"""Generates the PARTS-INDEX documents of an oss-cad-suite package.

One document per architecture, written to the root of the package next to
BUILD-INFO.json:

    ICE40-PARTS-INDEX.json  ECP5-PARTS-INDEX.json  GOWIN-PARTS-INDEX.json
    MACHXO2-PARTS-INDEX.json (catalog only, apio has no such architecture)

The documents are generated from the databases that travel INSIDE the
package (never from vendor catalogs), so a part is listed only if the
packaged toolchain can serve it:

    ice40    share/icebox/chipdb-*.txt          (.device and .pins sections)
    ecp5     share/trellis/database/devices.json + <family>/<device>/iodb.json
    gowin    apycula/*.msgpack.xz (vendor part table) and
             share/nextpnr/himbaechel/gowin/chipdb-*.bin (what nextpnr serves)
    machxo2  bin/nextpnr-machxo2 --list-devices, checked against devices.json

Every entry of the ice40, ecp5 and gowin documents carries a
'default-definition': the exact object that goes in apio's fpgas.jsonc under
the same key (the key is the fpga-id). 'definition-format' is the version of
that object's format. Policies that are not facts of the databases (the
device -> size label, the commercial grade only, the speed grade, the choice
between two silicon revisions) live in the tables below, each documented.

Usage:
    parts_indexes.py --suite <oss-cad-suite dir> --out <dir> [--build-info <json>]

The gowin device tables are read with the package's own interpreter
(<suite>/bin/tabbypy3), which ships apycula; this script re-invokes itself
under it with the hidden --dump-gowin option. Python 3.9+, stdlib only.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

GENERATOR = "tools-oss-cad-suite/parts_indexes.py 1.0.0"

# -- Version of the document format (header keys, part keys).
SCHEMA = 1

# -- Version of the format of 'default-definition' (the fpgas.jsonc object).
DEFINITION_FORMAT = 1

# -- The regex apio enforces on every fpga id (apio_definitions.py).
ID_FORMAT = re.compile(r"^[a-z][a-z0-9-]*$")

ARCHS = ("ice40", "ecp5", "gowin", "machxo2")


class GeneratorError(Exception):
    """The package does not have the shape this generator expects. Raised
    instead of emitting a document that silently lacks parts."""


# =========================== ICE40 ===========================
#
# Facts (icebox chipdb): each die file has a '.device <die> ...' line and one
# '.pins <package>' section per package; the 8k die also has '<pkg>:4k'
# sections, the packages of the 4k parts, which nextpnr-ice40 exposes as the
# lp4k/hx4k types (plain package names) on the same die.
#
# Policy (the vendor offering, seeded from apio-definitions fpgas.jsonc): a
# chipdb package says the die can be wired to it, not that Lattice sells that
# grade in it (there is no hx1k-cm36), so the packages each type is offered
# in are listed here. Every listed package must exist in the die (a hard
# error otherwise); a die package no type offers is reported as a warning.
#
# type -> (chipdb die, family, size label, offered packages).
#   die '8k:4k' = the 8k die, '<pkg>:4k' sections.
#   size: the label of fpgas.jsonc; 'up3k' -> '3k' and 'u1k'/'u2k' -> '1k'/'2k'
#   are new, taken from the type name.
ICE40_TYPES: Dict[str, Tuple[str, str, str, List[str]]] = {
    "lp384": ("384", "iCE40LP", "384", ["cm36", "cm49", "qn32"]),
    "lp1k": (
        "1k",
        "iCE40LP",
        "1k",
        ["swg16tr", "cm36", "cm49", "cm81", "cm121", "qn84", "cb81", "cb121"],
    ),
    "hx1k": ("1k", "iCE40HX", "1k", ["cb132", "vq100", "tq144"]),
    "lp4k": ("8k:4k", "iCE40LP", "4k", ["cm81", "cm121", "cm225"]),
    "hx4k": ("8k:4k", "iCE40HX", "4k", ["cb132", "tq144", "bg121"]),
    "lp8k": ("8k", "iCE40LP", "8k", ["cm81", "cm121", "cm225"]),
    "hx8k": ("8k", "iCE40HX", "8k", ["cm225", "cb132", "ct256", "bg121"]),
    "up3k": ("5k", "iCE40UP", "3k", ["sg48", "uwg30"]),
    "up5k": ("5k", "iCE40UP", "5k", ["sg48", "uwg30"]),
    "u1k": ("u4k", "iCE5LP", "1k", ["sg48"]),
    "u2k": ("u4k", "iCE5LP", "2k", ["sg48"]),
    "u4k": ("u4k", "iCE5LP", "4k", ["sg48"]),
}

# -- The 4k parts also appear oversized as their 8k sibling (same silicon,
# -- the '<pkg>:4k' package) as fpgas.jsonc does: id suffix '-8k'.
ICE40_OVERSIZED = {"lp4k": "lp8k", "hx4k": "hx8k"}

# -- Dies that no nextpnr-ice40 type maps to (the lm4k die is not served).
# -- Likewise the 'ul1k' type of apio's fpgas.jsonc is not an option of
# -- nextpnr-ice40 and no die has its cm36a package, so it is not listed.
ICE40_UNSERVED_DIES = ("lm4k",)


def read_icebox_chipdb(path: Path) -> Tuple[str, List[str]]:
    """Returns (die, packages) from an icebox chipdb text file."""
    die = ""
    packages: List[str] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            if line.startswith(".device "):
                die = line.split()[1]
            elif line.startswith(".pins "):
                packages.append(line.split()[1])
    if not die:
        raise GeneratorError(f"no '.device' line in {path}")
    return die, packages


def ice40_stem(type_: str) -> str:
    """'ice40lp1k' for a type; the iCE5LP types spell 'ice5lp4k'."""
    if type_.startswith("u") and not type_.startswith("up"):
        return "ice5lp" + type_[1:]
    return "ice40" + type_


def ice40_parts(suite: Path, warnings: List[str]) -> Dict[str, Any]:
    dies: Dict[str, List[str]] = {}
    for path in sorted((suite / "share/icebox").glob("chipdb-*.txt")):
        die, packages = read_icebox_chipdb(path)
        dies[die] = packages
    parts: Dict[str, Any] = {}
    covered = set()

    def add(type_: str, id_type: str, package: str, chipdb_pkg: str) -> None:
        """One entry: nextpnr type 'type_'; id and part number are those of
        'id_type' (they differ for the oversized 4k parts)."""
        die_spec, family, size, _ = ICE40_TYPES[type_]
        stem = ice40_stem(id_type)
        oversized = type_ != id_type
        fpga_id = f"{stem}-{package}" + ("-8k" if oversized else "")
        part_num = f"{stem.upper()}-{package.upper()}"
        parts[fpga_id] = {
            "part-num": part_num,
            "family": family,
            "device": die_spec.split(":")[0],
            "package": package,
            "generated": True,
            "definition-format": DEFINITION_FORMAT,
            "default-definition": {
                "part-num": part_num,
                "arch": "ice40",
                "size": size,
                "ice40-params": {"type": type_, "package": chipdb_pkg},
            },
        }

    for type_, (die_spec, _family, _size, offered) in ICE40_TYPES.items():
        die = die_spec.split(":")[0]
        suffix = ":4k" if die_spec.endswith(":4k") else ""
        if die not in dies:
            raise GeneratorError(f"ice40 type {type_}: no chipdb for die {die}")
        for package in offered:
            key = package + suffix
            if key not in dies[die]:
                raise GeneratorError(
                    f"ice40 type {type_}: package {key} not in the {die} chipdb"
                )
            covered.add((die, key))
            add(type_, type_, package, package)
            if type_ in ICE40_OVERSIZED:
                add(ICE40_OVERSIZED[type_], type_, package, key)
    for die, packages in dies.items():
        if die in ICE40_UNSERVED_DIES:
            continue
        for key in packages:
            if (die, key) not in covered:
                warnings.append(
                    f"ice40: chipdb {die} package {key} is offered by no type"
                )
    return parts


# =========================== ECP5 ===========================
#
# Facts: devices.json lists the device (idcode, family) and the pin database
# of each device (<family>/<device>/iodb.json) lists the packages nextpnr-ecp5
# accepts for it (devices.json's own package list is wider and nextpnr
# rejects some of them, e.g. caBGA554 on the 12F).
#
# Policy: one speed per part, the slowest grade offered in the family
# ('--speed' of nextpnr-ecp5; the 5G family only has grade 8), commercial
# grade only ('C'), size label = the die's LUT class in thousands.
ECP5_DEFAULT_SPEED = {"LFE5U": "6", "LFE5UM": "6", "LFE5UM5G": "8"}

# -- Lattice ordering-code letters of the package families.
ECP5_PACKAGE_CODE = {"CABGA": "BG", "CSFBGA": "MG", "TQFP": "TG"}

# -- The nextpnr-ecp5 '--<type>' prefix of each series.
ECP5_TYPE_PREFIX = {"LFE5U": "", "LFE5UM": "um-", "LFE5UM5G": "um5g-"}


def ecp5_parts(suite: Path) -> Dict[str, Any]:
    db_dir = suite / "share/trellis/database"
    devices = json.loads((db_dir / "devices.json").read_text(encoding="utf-8"))[
        "families"
    ]["ECP5"]["devices"]
    parts: Dict[str, Any] = {}
    for device in sorted(devices):
        match = re.fullmatch(r"(LFE5U[M5G]*)-(\d+)([A-Z])", device)
        if not match or match.group(1) not in ECP5_DEFAULT_SPEED:
            raise GeneratorError(f"unknown ecp5 device {device}")
        series, luts, letter = match.groups()
        speed = ECP5_DEFAULT_SPEED[series]
        type_ = f"{ECP5_TYPE_PREFIX[series]}{luts}k"
        iodb = json.loads(
            (db_dir / "ECP5" / device / "iodb.json").read_text(encoding="utf-8")
        )
        for package in sorted(iodb["packages"]):
            pkg = re.fullmatch(r"([A-Z]+)(\d+)", package)
            if not pkg or pkg.group(1) not in ECP5_PACKAGE_CODE:
                raise GeneratorError(f"unknown ecp5 package {package} on {device}")
            code = ECP5_PACKAGE_CODE[pkg.group(1)] + pkg.group(2)
            part_num = f"{series}-{luts}{letter}-{speed}{code}C"
            parts[part_num.lower()] = {
                "part-num": part_num,
                "family": series,
                "device": device,
                "package": package,
                "speed": speed,
                "generated": True,
                "definition-format": DEFINITION_FORMAT,
                "default-definition": {
                    "part-num": part_num,
                    "arch": "ecp5",
                    "size": f"{luts}k",
                    "ecp5-params": {"type": type_, "package": package, "speed": speed},
                },
            }
    return parts


# =========================== GOWIN ===========================
#
# Facts: apycula's per-device database has the table vendor part ->
# (package, die, speed), and nextpnr-himbaechel ships one chipdb-<device>.bin
# per device it can place. A part is listed when its device has BOTH (the
# packer and the placer); the apycula 'GW1N-2' has no nextpnr chipdb and is
# therefore not listed. The part number is the vendor's, verbatim ('/' -> '-'
# in the id). Engineering samples ('ES') and other grades are listed as
# apycula lists them.
#
# The definition params:
#   packer-device   = the apycula device file (gowin_pack -d).
#   yosys-family    = 'gw2a' / 'gw5a' by device series, empty for GW1N*.
#   nextpnr-family  = the device, for the devices that share part numbers
#                     with a sibling silicon revision (GW1N-9/9C, GW2A-18/18C):
#                     nextpnr-himbaechel refuses those without --vopt family=
#                     ("For the GW1N-9 series you need to specify --vopt
#                     family=..."); empty otherwise (measured: every other
#                     device places without it).
GOWIN_SIZE = {
    "GW1N-1": "1k",
    "GW1N-4": "4k",
    "GW1N-9": "9k",
    "GW1N-9C": "9k",
    "GW1NS-4": "4k",
    "GW1NZ-1": "1k",
    "GW2A-18": "20k",
    "GW2A-18C": "20k",
    "GW5A-25A": "25k",
    "GW5AST-138C": "138k",
    "GW5AT-60B": "60k",
}

# -- A vendor part that two silicon revisions serve gets this device by
# -- default (today's choice of fpgas.jsonc); the other stays visible in
# -- 'alt-devices'. Two candidates and none preferred is a hard error.
GOWIN_PREFERRED_DEVICES = ("GW1N-9C", "GW2A-18")

# -- Devices whose nextpnr database ships but does not place a minimal
# -- design: listed with generated=false and the reason.
GOWIN_UNUSABLE = {
    "GW5AT-60B": (
        "the packaged nextpnr-himbaechel database of this device is incomplete: "
        "a minimal design fails to place (no BUFG BELs remain)"
    )
}


def gowin_yosys_family(device: str) -> str:
    if device.startswith("GW2A"):
        return "gw2a"
    if device.startswith("GW5A"):
        return "gw5a"
    return ""


def dump_gowin(suite: Path) -> Dict[str, Dict[str, List[str]]]:
    """Runs under the suite's interpreter: {device: {part: [pkg, die, speed]}}."""
    from apycula import chipdb  # pylint: disable=import-outside-toplevel

    root = Path(chipdb.__file__).parent
    out = {}
    for path in sorted(root.glob("*.msgpack.xz")):
        device = path.name.removesuffix(".msgpack.xz")
        db = chipdb.load_chipdb(str(path))
        out[device] = {k: list(v) for k, v in sorted(db.packages.items())}
    return out


def read_gowin_tables(suite: Path) -> Dict[str, Dict[str, List[str]]]:
    python = suite / "bin" / "tabbypy3"
    env = dict(os.environ, PYTHONWARNINGS="ignore")
    proc = subprocess.run(
        [
            str(python),
            str(Path(__file__).resolve()),
            "--dump-gowin",
            "--suite",
            str(suite),
        ],
        check=True,
        capture_output=True,
        text=True,
        env=env,
    )
    return json.loads(proc.stdout)


def gowin_parts(
    suite: Path, tables: Optional[Dict[str, Dict[str, List[str]]]] = None
) -> Dict[str, Any]:
    tables = tables if tables is not None else read_gowin_tables(suite)
    chipdbs = {
        p.name.removeprefix("chipdb-").removesuffix(".bin")
        for p in (suite / "share/nextpnr/himbaechel/gowin").glob("chipdb-*.bin")
    }
    served = sorted(set(tables) & chipdbs)
    if not served:
        raise GeneratorError(
            "no gowin device with both an apycula and a nextpnr database"
        )

    # -- part -> devices that serve it.
    candidates: Dict[str, List[str]] = {}
    for device in served:
        for part in tables[device]:
            candidates.setdefault(part, []).append(device)

    # -- Devices that need an explicit nextpnr family.
    ambiguous = {d for devs in candidates.values() if len(devs) > 1 for d in devs}

    parts: Dict[str, Any] = {}
    for part, devices in sorted(candidates.items()):
        chosen_list = [d for d in devices if d in GOWIN_PREFERRED_DEVICES]
        if len(devices) == 1:
            device = devices[0]
        elif len(chosen_list) == 1:
            device = chosen_list[0]
        else:
            raise GeneratorError(
                f"gowin part {part} is served by {devices}: "
                "choose a default in GOWIN_PREFERRED_DEVICES"
            )
        if device not in GOWIN_SIZE:
            raise GeneratorError(
                f"gowin device {device} has no size label: extend GOWIN_SIZE"
            )
        package, _die, speed = tables[device][part]
        fpga_id = part.lower().replace("/", "-")
        entry: Dict[str, Any] = {
            "part-num": part,
            "family": part.split("-")[0],
            "device": device,
            "package": package,
            "speed": speed,
            "generated": device not in GOWIN_UNUSABLE,
            "definition-format": DEFINITION_FORMAT,
            "default-definition": {
                "part-num": part,
                "arch": "gowin",
                "size": GOWIN_SIZE[device],
                "gowin-params": {
                    "yosys-family": gowin_yosys_family(device),
                    "nextpnr-family": device if device in ambiguous else "",
                    "packer-device": device,
                },
            },
        }
        if device in GOWIN_UNUSABLE:
            entry["not-generated-reason"] = GOWIN_UNUSABLE[device]
        alternatives = sorted(d for d in devices if d != device)
        if alternatives:
            entry["alt-devices"] = alternatives
        if fpga_id in parts:
            raise GeneratorError(f"gowin id collision: {fpga_id}")
        parts[fpga_id] = entry
    return parts


# =========================== MACHXO2 ===========================
#
# Catalog only (apio has no such architecture, so no default-definition).
# Facts: nextpnr-machxo2 --list-devices names every full part it serves;
# devices.json (families MachXO2 / MachXO3) must know each variant with that
# speed and grade. Policy: commercial grade only; one entry per speed grade
# since the full part number carries it. MachXO, MachXO3 (non L/LF) and
# MachXO3D are not listed by that nextpnr, hence not here.
MACHXO2_PART = re.compile(r"(LC[A-Z0-9]+-\d+[A-Z]+)-(\d)([A-Z]+\d+)([CI])")


def read_machxo2_list(suite: Path) -> str:
    proc = subprocess.run(
        [str(suite / "bin" / "nextpnr-machxo2"), "--list-devices"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,  # nextpnr logs the list to stderr
        text=True,
    )
    return proc.stdout


def machxo2_parts(suite: Path, list_text: Optional[str] = None) -> Dict[str, Any]:
    list_text = list_text if list_text is not None else read_machxo2_list(suite)
    families = json.loads(
        (suite / "share/trellis/database/devices.json").read_text(encoding="utf-8")
    )["families"]
    variants: Dict[str, Any] = {}
    for family in ("MachXO2", "MachXO3"):
        for device, info in families[family]["devices"].items():
            for variant, vinfo in info["variants"].items():
                variants[variant] = dict(vinfo, device=device)
    parts: Dict[str, Any] = {}
    for line in list_text.splitlines():
        name = line.strip()
        if not name.startswith("LC"):
            continue
        match = MACHXO2_PART.fullmatch(name)
        if not match:
            raise GeneratorError(f"unparseable machxo2 part {name}")
        variant, speed, package, grade = match.groups()
        if variant not in variants:
            raise GeneratorError(
                f"machxo2 part {name}: variant {variant} not in devices.json"
            )
        if grade == "I":
            continue
        info = variants[variant]
        if int(speed) not in info["speeds"] or grade not in info["suffixes"]:
            raise GeneratorError(
                f"machxo2 part {name}: speed/grade not in devices.json"
            )
        parts[name.lower()] = {
            "part-num": name,
            "family": variant.split("-")[0],
            "device": info["device"],
            "package": package,
            "speed": speed,
            "generated": True,
        }
    if not parts:
        raise GeneratorError("nextpnr-machxo2 lists no device")
    return parts


# =========================== documents ===========================

_SAME_KEY = (
    "Each default-definition is the object for the fpgas.jsonc entry with the same key."
)
NOTES = {
    "ice40": "Generated from the icebox databases of this package. " + _SAME_KEY,
    "ecp5": "Generated from the trellis databases of this package. " + _SAME_KEY,
    "gowin": (
        "Generated from the apycula and nextpnr databases of this package. " + _SAME_KEY
    ),
    "machxo2": (
        "Generated from the trellis databases and nextpnr-machxo2 of this "
        "package. Catalog only: apio has no machxo2 architecture, so entries "
        "have no default-definition."
    ),
}


def suite_tag(suite: Path) -> str:
    """'2026-09-27' from the suite's version file ('20260927'): VERSION in an
    unpacked oss-cad-suite, YOSYS-VERSION in our package (build.py renames it)."""
    for name in ("YOSYS-VERSION", "VERSION"):
        if (suite / name).is_file():
            version = (suite / name).read_text(encoding="utf-8").strip()
            break
    else:
        raise GeneratorError(f"no VERSION or YOSYS-VERSION in {suite}")
    if not re.fullmatch(r"\d{8}", version):
        raise GeneratorError(f"unexpected suite version {version!r}")
    return f"{version[:4]}-{version[4:6]}-{version[6:]}"


def generate(
    suite: Path,
    build_info: Optional[Dict[str, Any]] = None,
    gowin_tables: Optional[Dict[str, Dict[str, List[str]]]] = None,
    machxo2_list: Optional[str] = None,
) -> Tuple[Dict[str, Dict[str, Any]], List[str]]:
    """Returns ({arch: document}, warnings)."""
    tag = suite_tag(suite)
    if build_info is not None and build_info["yosys-release-tag"] != tag:
        raise GeneratorError(
            f"build info yosys-release-tag {build_info['yosys-release-tag']} "
            f"!= suite {tag}"
        )
    warnings: List[str] = []
    parts_by_arch = {
        "ice40": ice40_parts(suite, warnings),
        "ecp5": ecp5_parts(suite),
        "gowin": gowin_parts(suite, gowin_tables),
        "machxo2": machxo2_parts(suite, machxo2_list),
    }
    docs = {}
    for arch, parts in parts_by_arch.items():
        for fpga_id in parts:
            if not ID_FORMAT.match(fpga_id):
                raise GeneratorError(f"invalid {arch} id {fpga_id}")
        docs[arch] = {
            "schema": SCHEMA,
            "arch": arch,
            "note": NOTES[arch],
            "generator": GENERATOR,
            "yosys-release-tag": tag,
            "parts-count": len(parts),
            "parts": parts,
        }
    return docs, warnings


def check_no_collisions(docs: Dict[str, Dict[str, Any]]) -> None:
    seen: Dict[str, str] = {}
    for arch, doc in docs.items():
        for fpga_id in doc["parts"]:
            if fpga_id in seen:
                raise GeneratorError(f"id {fpga_id} in both {seen[fpga_id]} and {arch}")
            seen[fpga_id] = arch


def write_documents(docs: Dict[str, Dict[str, Any]], out_dir: Path) -> List[Path]:
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for arch, doc in docs.items():
        path = out_dir / f"{arch.upper()}-PARTS-INDEX.json"
        path.write_text(
            json.dumps(doc, indent=2, sort_keys=True) + "\n", encoding="utf-8"
        )
        paths.append(path)
    return paths


# =========================== cross-platform check ===========================


def database_hashes(suite: Path) -> Dict[str, str]:
    """sha256 of every database file the generator reads, keyed by a path
    relative to the suite root that is the same on every platform. The
    documents are generated once (linux) and copied to the three platform
    packages, which is only sound if these are identical on all of them."""
    files: Dict[str, Path] = {}
    trellis = suite / "share/trellis/database"
    files["share/trellis/database/devices.json"] = trellis / "devices.json"
    for iodb in sorted(trellis.glob("*/*/iodb.json")):
        files[iodb.relative_to(suite).as_posix()] = iodb
    for chipdb in sorted((suite / "share/icebox").glob("chipdb-*.txt")):
        files[chipdb.relative_to(suite).as_posix()] = chipdb
    for msgpack in sorted(
        (suite / "lib").glob("python3*/site-packages/apycula/*.msgpack.xz")
    ):
        files[f"apycula/{msgpack.name}"] = msgpack
    for chipdb in sorted(
        (suite / "share/nextpnr/himbaechel/gowin").glob("chipdb-*.bin")
    ):
        files[chipdb.relative_to(suite).as_posix()] = chipdb
    hashes = {}
    for key, path in files.items():
        digest = hashlib.sha256()
        with path.open("rb") as f:
            for block in iter(lambda: f.read(1 << 20), b""):
                digest.update(block)
        hashes[key] = digest.hexdigest()
    return hashes


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument(
        "--suite", required=True, type=Path, help="oss-cad-suite directory"
    )
    parser.add_argument("--out", type=Path, help="directory for the four documents")
    parser.add_argument(
        "--build-info", type=Path, help="build-info.json (yosys-release-tag is checked)"
    )
    parser.add_argument("--dump-gowin", action="store_true", help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.dump_gowin:
        json.dump(dump_gowin(args.suite), sys.stdout)
        return
    if args.out is None:
        parser.error("--out is required")
    build_info = (
        json.loads(args.build_info.read_text(encoding="utf-8"))
        if args.build_info
        else None
    )
    docs, warnings = generate(args.suite, build_info)
    check_no_collisions(docs)
    for warning in warnings:
        print(f"WARNING: {warning}", file=sys.stderr)
    for path in write_documents(docs, args.out):
        print(f"{path}: {docs[path.name.split('-')[0].lower()]['parts-count']} parts")


if __name__ == "__main__":
    main()
