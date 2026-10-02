"""Generates the four <ARCH>-PARTS-INDEX.json files that every package carries.

    parts_indexes.py --yosys-release-tag <tag> --release-tag <tag> --out <dir>

Downloads the linux-x64 oss-cad-suite of that YosysHQ release to
_upstream/parts-indexes/ and generates from the databases inside it, so a part
is listed only if the packaged toolchain can serve it. The databases are the
same on the three platforms, so the files are generated once and build.py
copies them into every package. '--suite <dir>' uses an already extracted
suite instead of downloading one.

    ice40    share/icebox/chipdb-*.txt
    ecp5     share/trellis/database/devices.json + ECP5/<device>/iodb.json
    gowin    apycula's *.msgpack.xz (read with the suite's bin/tabbypy3) and
             share/nextpnr/himbaechel/gowin/chipdb-*.bin
    machxo2  bin/nextpnr-machxo2 --list-devices + devices.json
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

YOSYS_RELEASES_URL = "https://github.com/YosysHQ/oss-cad-suite-build/releases/download"

# -- The regex apio enforces on every fpga id.
ID_FORMAT = re.compile(r"^[a-z][a-z0-9-]*$")

# =========================== ICE40 ===========================

# -- type -> (icebox die, family, size, offered packages); die '8k:4k' = the
# -- '<pkg>:4k' packages of the 8k die. There is no 'ul1k' type in nextpnr.
ICE40_TYPES = {
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

# -- The 4k parts are also listed as their 8k die, with the id suffix '-8k'.
ICE40_OVERSIZED = {"lp4k": "lp8k", "hx4k": "hx8k"}


def ice40_parts(suite):
    dies = {}
    for path in (suite / "share/icebox").glob("chipdb-*.txt"):
        lines = path.read_text(encoding="utf-8").splitlines()
        die = [x.split()[1] for x in lines if x.startswith(".device ")][0]
        dies[die] = {x.split()[1] for x in lines if x.startswith(".pins ")}

    parts = {}
    for type_, (die_spec, family, _, packages) in ICE40_TYPES.items():
        die, _, suffix = die_spec.partition(":")
        # -- The iCE5LP types (u1k, u2k, u4k) spell 'ice5lp<size>'.
        stem = (
            "ice5lp" + type_[1:]
            if type_[:2] != "up" and type_[0] == "u"
            else "ice40" + type_
        )
        for package in packages:
            chipdb_package = f"{package}:{suffix}" if suffix else package
            if chipdb_package not in dies.get(die, ()):
                sys.exit(f"ice40 {type_}: package {chipdb_package} not in die {die}")
            part_num = f"{stem.upper()}-{package.upper()}"
            variants = [("", type_, package)]
            if type_ in ICE40_OVERSIZED:
                variants.append(("-8k", ICE40_OVERSIZED[type_], chipdb_package))
            for id_suffix, nextpnr_type, nextpnr_package in variants:
                parts[f"{stem}-{package}{id_suffix}"] = {
                    "part-num": part_num,
                    "family": family,
                    "generated": True,
                    "default-definition": {
                        "part-num": part_num,
                        "arch": "ice40",
                        "size": ICE40_TYPES[nextpnr_type][2],
                        "ice40-params": {
                            "type": nextpnr_type,
                            "package": nextpnr_package,
                        },
                    },
                }
    return parts


# =========================== ECP5 ===========================

# -- series -> (speed grade of the parts, nextpnr '--<type>' prefix).
ECP5_SERIES = {"LFE5U": ("6", ""), "LFE5UM": ("6", "um-"), "LFE5UM5G": ("8", "um5g-")}

# -- Lattice ordering-code letters of the package families.
ECP5_PACKAGE_CODE = {"CABGA": "BG", "CSFBGA": "MG", "TQFP": "TG"}


def ecp5_parts(suite):
    database = suite / "share/trellis/database"
    devices = json.loads((database / "devices.json").read_text(encoding="utf-8"))
    parts = {}
    for device in devices["families"]["ECP5"]["devices"]:
        series, luts, letter = re.fullmatch(
            r"(LFE5U[M5G]*)-(\d+)([A-Z])", device
        ).groups()
        speed, type_prefix = ECP5_SERIES[series]
        iodb = json.loads((database / "ECP5" / device / "iodb.json").read_text())
        # -- iodb.json lists the packages nextpnr accepts (devices.json more).
        for package in iodb["packages"]:
            name, pins = re.fullmatch(r"([A-Z]+)(\d+)", package).groups()
            part_num = (
                f"{series}-{luts}{letter}-{speed}{ECP5_PACKAGE_CODE[name]}{pins}C"
            )
            parts[part_num.lower()] = {
                "part-num": part_num,
                "family": series,
                "generated": True,
                "default-definition": {
                    "part-num": part_num,
                    "arch": "ecp5",
                    "size": f"{luts}k",
                    "ecp5-params": {
                        "type": f"{type_prefix}{luts}k",
                        "package": package,
                        "speed": speed,
                    },
                },
            }
    return parts


# =========================== GOWIN ===========================

# -- Size label of each device.
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

# -- A part that two silicon revisions serve gets this one (as fpgas.jsonc).
GOWIN_PREFERRED_DEVICES = ("GW1N-9C", "GW2A-18")

# -- nextpnr ships a database for it but cannot place a blinky: generated=false.
GOWIN_UNUSABLE = ("GW5AT-60B",)


def gowin_yosys_family(device):
    """The yosys synth_gowin -family of a device series."""
    return {"GW2A": "gw2a", "GW5A": "gw5a"}.get(device[:4], "")


def dump_gowin():
    """Run under the suite's interpreter: {device: {part: [package, die, speed]}}."""
    from apycula import chipdb  # pylint: disable=import-outside-toplevel

    tables = {}
    for path in sorted(Path(chipdb.__file__).parent.glob("*.msgpack.xz")):
        packages = chipdb.load_chipdb(str(path)).packages
        tables[path.name.split(".")[0]] = {k: list(v) for k, v in packages.items()}
    json.dump(tables, sys.stdout)


def gowin_parts(suite):
    output = subprocess.run(
        [str(suite / "bin/tabbypy3"), __file__, "--dump-gowin"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    tables = json.loads(output)
    chipdbs = (suite / "share/nextpnr/himbaechel/gowin").glob("chipdb-*.bin")
    # -- A device needs both the packer (apycula) and the placer (nextpnr) db.
    devices = sorted(set(tables) & {p.stem.removeprefix("chipdb-") for p in chipdbs})

    candidates = {}  # part -> the devices that serve it
    for device in devices:
        for part in tables[device]:
            candidates.setdefault(part, []).append(device)
    # -- nextpnr needs the family of a device that shares parts with another.
    shared = {d for devs in candidates.values() if len(devs) > 1 for d in devs}

    parts = {}
    for part, devs in sorted(candidates.items()):
        if len(devs) > 1:
            devs = [d for d in devs if d in GOWIN_PREFERRED_DEVICES]
            if len(devs) != 1:
                sys.exit(f"gowin {part}: add a device to GOWIN_PREFERRED_DEVICES")
        device = devs[0]
        parts[part.lower().replace("/", "-")] = {
            "part-num": part,
            "family": part.split("-")[0],
            "generated": device not in GOWIN_UNUSABLE,
            "default-definition": {
                "part-num": part,
                "arch": "gowin",
                "size": GOWIN_SIZE[device],
                "gowin-params": {
                    "yosys-family": gowin_yosys_family(device),
                    "nextpnr-family": device if device in shared else "",
                    "packer-device": device,
                },
            },
        }
    return parts


# =========================== MACHXO2 ===========================

# -- Catalog only (apio has no machxo2 arch); commercial grade only.
MACHXO2_PART = re.compile(r"(LC[A-Z0-9]+-\d+[A-Z]+)-(\d)([A-Z]+\d+)C")


def machxo2_parts(suite):
    # -- nextpnr prints the list to stderr.
    listing = subprocess.run(
        [str(suite / "bin/nextpnr-machxo2"), "--list-devices"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    ).stdout
    database = suite / "share/trellis/database/devices.json"
    families = json.loads(database.read_text(encoding="utf-8"))["families"]
    variants = {}
    for family in ("MachXO2", "MachXO3"):
        for device, info in families[family]["devices"].items():
            for variant, variant_info in info["variants"].items():
                variants[variant] = (device, variant_info)
    parts = {}
    for name in listing.split():
        match = MACHXO2_PART.fullmatch(name)
        if not match:
            continue
        variant, speed, package = match.groups()
        device, variant_info = variants[variant]
        if int(speed) not in variant_info["speeds"]:
            sys.exit(f"machxo2 {name}: speed not in devices.json")
        parts[name.lower()] = {
            "part-num": name,
            "family": variant.split("-")[0],
            "device": device,
            "package": package,
            "speed": speed,
            "generated": True,
        }
    return parts


# =========================== json files ===========================

NOTE = (
    "Keyed by the fpga-id, the lowercase part number ('/' -> '-'), e.g. {example}. "
    "Generated from the {source} of the oss-cad-suite in this package, so only "
    "parts its toolchain knows are listed. {definition} An entry with "
    "generated=false is a part the toolchain knows but cannot build."
)
DEFINITION = (
    "default-definition is the object of apio's fpgas.jsonc entry with the same key."
)
NOTES = {
    "ice40": NOTE.format(
        example="ice40hx8k-ct256 (a 4k part also appears as its 8k die, id suffix -8k)",
        source="icebox databases",
        definition=DEFINITION,
    ),
    "ecp5": NOTE.format(
        example="lfe5u-25f-6bg256c", source="trellis databases", definition=DEFINITION
    ),
    "gowin": NOTE.format(
        example="gw1nr-lv9qn88pc6-i5",
        source="apycula and nextpnr databases",
        definition=DEFINITION,
    ),
    "machxo2": NOTE.format(
        example="lcmxo2-1200hc-4sg32c",
        source="trellis database and nextpnr-machxo2",
        definition="Catalog only: apio has no machxo2 architecture, so there is no "
        "default-definition.",
    ),
}


def generate(suite, release_tag):
    """Returns {arch: json_data}."""
    json_data = {}
    for arch, parts_function in (
        ("ice40", ice40_parts),
        ("ecp5", ecp5_parts),
        ("gowin", gowin_parts),
        ("machxo2", machxo2_parts),
    ):
        parts = dict(sorted(parts_function(suite).items()))
        bad_ids = [i for i in parts if not ID_FORMAT.match(i)]
        if not parts or bad_ids:
            sys.exit(f"{arch}: no parts or invalid ids {bad_ids}")
        json_data[arch] = {
            "schema": 8,
            "date": release_tag.replace("-", ""),
            "release-tag": release_tag,
            "part-count": len(parts),
            "generated-count": sum(p["generated"] for p in parts.values()),
            "note": NOTES[arch],
            "parts": parts,
        }
    return json_data


def write_json_file(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def download_suite(yosys_release_tag):
    """Downloads and extracts the linux-x64 suite; returns its directory."""
    fname = f"oss-cad-suite-linux-x64-{yosys_release_tag.replace('-', '')}.tgz"
    work_dir = Path("_upstream/parts-indexes")
    shutil.rmtree(work_dir, ignore_errors=True)
    work_dir.mkdir(parents=True)
    url = f"{YOSYS_RELEASES_URL}/{yosys_release_tag}/{fname}"
    subprocess.run(["wget", "-nv", url], cwd=work_dir, check=True)
    subprocess.run(["tar", "zxf", fname], cwd=work_dir, check=True)
    (work_dir / fname).unlink()
    return work_dir / "oss-cad-suite"


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--yosys-release-tag", help="YosysHQ release to download")
    source.add_argument("--suite", type=Path, help="an extracted oss-cad-suite")
    parser.add_argument("--release-tag", required=True, help="of this package")
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    suite = args.suite or download_suite(args.yosys_release_tag)
    json_data = generate(suite, args.release_tag)
    args.out.mkdir(parents=True, exist_ok=True)
    for arch, data in json_data.items():
        json_file = args.out / f"{arch.upper()}-PARTS-INDEX.json"
        write_json_file(json_file, data)
        print(f"{json_file}: {data['part-count']} parts")


if __name__ == "__main__":
    if sys.argv[1:] == ["--dump-gowin"]:
        dump_gowin()
    else:
        main()
