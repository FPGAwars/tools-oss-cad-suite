"""Tests of .github/workflows/parts_indexes.py.

Run from the repo root:

    OSS_CAD_SUITE_DIR=<an unpacked oss-cad-suite for THIS platform> \
    APIO_DEFINITIONS_DIR=<clone of FPGAwars/apio-definitions> \
    python -m pytest tests/ -v

The builder does not run them. Tests that need a suite tree are skipped when
OSS_CAD_SUITE_DIR is not set (or has no VERSION file); the oracle needs
APIO_DEFINITIONS_DIR and the proto check needs the 'apio' package importable
(pip install -e <apio clone>). Generating from a suite takes about 40 seconds
(the apycula databases are read with the suite's own interpreter).
"""

import importlib.util
import json
import os
import re
import subprocess
from pathlib import Path

import pytest

MODULE_PATH = (
    Path(__file__).resolve().parent.parent / ".github/workflows/parts_indexes.py"
)
spec = importlib.util.spec_from_file_location("parts_indexes", MODULE_PATH)
pi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pi)

SUITE = (
    Path(os.environ["OSS_CAD_SUITE_DIR"])
    if os.environ.get("OSS_CAD_SUITE_DIR")
    else None
)
DEFINITIONS = (
    Path(os.environ["APIO_DEFINITIONS_DIR"])
    if os.environ.get("APIO_DEFINITIONS_DIR")
    else None
)

needs_suite = pytest.mark.skipif(
    SUITE is None
    or not any((SUITE / n).is_file() for n in ("VERSION", "YOSYS-VERSION")),
    reason="OSS_CAD_SUITE_DIR does not point to an oss-cad-suite tree",
)
needs_definitions = pytest.mark.skipif(
    DEFINITIONS is None or not (DEFINITIONS / "definitions/fpgas.jsonc").is_file(),
    reason="APIO_DEFINITIONS_DIR does not point to apio-definitions",
)

# -- Entries of fpgas.jsonc that the packaged toolchain cannot serve, with the
# -- measured reason. The oracle test requires every OTHER ice40/ecp5/gowin
# -- entry to be reproduced exactly, and this one to stay absent (when the
# -- toolchain gains the device, this test says so and the entry moves out).
KNOWN_UNSERVABLE = {
    "ice40ul1k-cm36a": (
        "type 'ul1k' is not an option of nextpnr-ice40 and no icebox die has "
        "the cm36a package"
    ),
}


@pytest.fixture(scope="session")
def docs():
    generated, _warnings = pi.generate(SUITE)
    pi.check_no_collisions(generated)
    return generated


def load_fpgas_jsonc():
    text = (DEFINITIONS / "definitions/fpgas.jsonc").read_text(encoding="utf-8")
    return json.loads(re.sub(r"^\s*//.*$", "", text, flags=re.M))


# ---------------------------------------------------------------- (a) proto


@needs_suite
def test_default_definitions_validate_against_the_apio_proto(docs):
    json_format = pytest.importorskip("google.protobuf.json_format")
    pb2 = pytest.importorskip("apio.common.proto.apio_definitions_pb2")
    checked = 0
    for arch in ("ice40", "ecp5", "gowin"):
        for fpga_id, part in docs[arch]["parts"].items():
            definition = pb2.FpgaDefinition()
            json_format.ParseDict(part["default-definition"], definition)
            assert definition.IsInitialized(), fpga_id
            assert definition.part_num == part["part-num"], fpga_id
            assert part["default-definition"]["arch"] == arch, fpga_id
            checked += 1
    assert checked == sum(docs[a]["parts-count"] for a in ("ice40", "ecp5", "gowin"))


# ---------------------------------------------------------------- (b) ids


@needs_suite
def test_ids_follow_the_apio_regex(docs):
    for arch, doc in docs.items():
        for fpga_id in doc["parts"]:
            assert pi.ID_FORMAT.match(fpga_id), (arch, fpga_id)


@needs_suite
@needs_definitions
def test_no_id_collides_across_architectures_or_with_xilinx(docs):
    xilinx_ids = {k for k, v in load_fpgas_jsonc().items() if v["arch"] == "xilinx"}
    assert xilinx_ids
    seen = set()
    for doc in docs.values():
        ids = set(doc["parts"])
        assert not ids & seen
        assert not ids & xilinx_ids
        seen |= ids


# ---------------------------------------------------------------- (c) oracle


@needs_suite
@needs_definitions
def test_oracle_every_hand_written_definition_is_reproduced(docs):
    oracle = {
        k: v
        for k, v in load_fpgas_jsonc().items()
        if v["arch"] in ("ice40", "ecp5", "gowin")
    }
    assert len(oracle) == 79  # 37 ice40 + 36 ecp5 + 6 gowin at the time of writing
    reproduced = 0
    for fpga_id, definition in oracle.items():
        part = docs[definition["arch"]]["parts"].get(fpga_id)
        if fpga_id in KNOWN_UNSERVABLE:
            assert part is None, f"{fpga_id} is served now: {KNOWN_UNSERVABLE[fpga_id]}"
            continue
        assert part is not None, f"{fpga_id} of fpgas.jsonc is missing from the index"
        assert part["default-definition"] == definition, fpga_id
        reproduced += 1
    assert reproduced == len(oracle) - len(KNOWN_UNSERVABLE)


# ---------------------------------------------------------------- (d) examples


EXAMPLES = {
    "ice40": (
        "ice40lp4k-cm81-8k",
        {
            "default-definition": {
                "arch": "ice40",
                "ice40-params": {"package": "cm81:4k", "type": "lp8k"},
                "part-num": "ICE40LP4K-CM81",
                "size": "8k",
            },
            "definition-format": 1,
            "device": "8k",
            "family": "iCE40LP",
            "generated": True,
            "package": "cm81",
            "part-num": "ICE40LP4K-CM81",
        },
    ),
    "ecp5": (
        "lfe5um5g-85f-8bg756c",
        {
            "default-definition": {
                "arch": "ecp5",
                "ecp5-params": {
                    "package": "CABGA756",
                    "speed": "8",
                    "type": "um5g-85k",
                },
                "part-num": "LFE5UM5G-85F-8BG756C",
                "size": "85k",
            },
            "definition-format": 1,
            "device": "LFE5UM5G-85F",
            "family": "LFE5UM5G",
            "generated": True,
            "package": "CABGA756",
            "part-num": "LFE5UM5G-85F-8BG756C",
            "speed": "8",
        },
    ),
    "gowin": (
        "gw1nr-lv9qn88pc6-i5",
        {
            "alt-devices": ["GW1N-9"],
            "default-definition": {
                "arch": "gowin",
                "gowin-params": {
                    "nextpnr-family": "GW1N-9C",
                    "packer-device": "GW1N-9C",
                    "yosys-family": "",
                },
                "part-num": "GW1NR-LV9QN88PC6/I5",
                "size": "9k",
            },
            "definition-format": 1,
            "device": "GW1N-9C",
            "family": "GW1NR",
            "generated": True,
            "package": "QFN88P",
            "part-num": "GW1NR-LV9QN88PC6/I5",
            "speed": "C6/I5",
        },
    ),
    "machxo2": (
        "lcmxo3lf-6900e-6mg324c",
        {
            "device": "LCMXO3-6900",
            "family": "LCMXO3LF",
            "generated": True,
            "package": "MG324",
            "part-num": "LCMXO3LF-6900E-6MG324C",
            "speed": "6",
        },
    ),
}


@needs_suite
@pytest.mark.parametrize("arch", sorted(EXAMPLES))
def test_fixed_example_per_architecture(docs, arch):
    fpga_id, expected = EXAMPLES[arch]
    assert docs[arch]["parts"][fpga_id] == expected


@needs_suite
def test_document_headers(docs):
    tag = pi.suite_tag(SUITE)
    for arch, doc in docs.items():
        assert doc["schema"] == 1
        assert doc["arch"] == arch
        assert doc["yosys-release-tag"] == tag
        assert doc["generator"].startswith("tools-oss-cad-suite/parts_indexes.py ")
        assert doc["parts-count"] == len(doc["parts"]) > 0
    assert not any("default-definition" in p for p in docs["machxo2"]["parts"].values())


# ---------------------------------------------------------------- (e) determinism


@needs_suite
def test_generation_is_deterministic(tmp_path):
    outputs = []
    for run in ("a", "b"):
        generated, _ = pi.generate(SUITE)
        paths = pi.write_documents(generated, tmp_path / run)
        outputs.append({p.name: p.read_bytes() for p in paths})
    assert outputs[0] == outputs[1]
    for content in outputs[0].values():
        assert content.endswith(b"}\n")
        assert content.startswith(b'{\n  "arch"')  # keys sorted, 2 spaces


# ---------------------------------------------------------------- nextpnr


def nextpnr_runs(binary):
    try:
        subprocess.run([str(binary), "--version"], check=True, capture_output=True)
        return True
    except (OSError, subprocess.CalledProcessError):
        return False


@needs_suite
def test_nextpnr_accepts_every_listed_ice40_and_ecp5_part(docs, tmp_path):
    """The package check of nextpnr ('Unsupported package') is the ground truth
    of what the placer can serve; the index must never list anything it
    rejects."""
    ice40, ecp5 = SUITE / "bin/nextpnr-ice40", SUITE / "bin/nextpnr-ecp5"
    if not (nextpnr_runs(ice40) and nextpnr_runs(ecp5)):
        pytest.skip("the nextpnr binaries of this suite do not run on this host")
    empty = tmp_path / "empty.json"
    top = {"attributes": {"top": 1}, "ports": {}, "cells": {}, "netnames": {}}
    empty.write_text(json.dumps({"creator": "t", "modules": {"top": top}}))
    for fpga_id, part in docs["ice40"]["parts"].items():
        params = part["default-definition"]["ice40-params"]
        cmd = [
            str(ice40),
            f"--{params['type']}",
            "--package",
            params["package"],
            "--json",
            str(empty),
            "--pack-only",
            "-q",
        ]
        out = subprocess.run(cmd, capture_output=True, text=True, check=False)
        assert "Unsupported package" not in out.stdout + out.stderr, (
            fpga_id,
            out.stderr,
        )
        assert "unrecognised option" not in out.stderr, (fpga_id, out.stderr)
    for fpga_id, part in docs["ecp5"]["parts"].items():
        params = part["default-definition"]["ecp5-params"]
        cmd = [
            str(ecp5),
            f"--{params['type']}",
            "--package",
            params["package"],
            "--speed",
            params["speed"],
            "--json",
            str(empty),
            "--pack-only",
            "-q",
        ]
        out = subprocess.run(cmd, capture_output=True, text=True, check=False)
        text = out.stdout + out.stderr
        assert "Unsupported package" not in text and "speed grade" not in text, (
            fpga_id,
            text,
        )


# ---------------------------------------------------------------- no suite needed


def fake_suite(tmp_path, gowin_devices):
    """A suite skeleton with just the gowin nextpnr chipdb file names."""
    directory = tmp_path / "share/nextpnr/himbaechel/gowin"
    directory.mkdir(parents=True)
    for device in gowin_devices:
        (directory / f"chipdb-{device}.bin").write_bytes(b"")
    return tmp_path


def test_gowin_part_served_by_two_revisions_needs_a_preferred_device(tmp_path):
    suite = fake_suite(tmp_path, ["GW1N-1", "GW1N-4"])
    tables = {
        "GW1N-1": {"GW1N-LV1QN48C6/I5": ["QFN48", "GW1N-1", "C6/I5"]},
        "GW1N-4": {"GW1N-LV1QN48C6/I5": ["QFN48", "GW1N-4", "C6/I5"]},
    }
    with pytest.raises(pi.GeneratorError, match="choose a default"):
        pi.gowin_parts(suite, tables)


def test_gowin_device_without_nextpnr_database_is_not_listed(tmp_path):
    suite = fake_suite(tmp_path, ["GW1N-1"])
    tables = {
        "GW1N-1": {"GW1N-LV1QN48C6/I5": ["QFN48", "GW1N-1", "C6/I5"]},
        "GW1N-2": {"GW1N-LV1P5LQ100C6/I5": ["LQFP100", "GW1N-1P5C", "C6/I5"]},
    }
    parts = pi.gowin_parts(suite, tables)
    assert list(parts) == ["gw1n-lv1qn48c6-i5"]
    assert parts["gw1n-lv1qn48c6-i5"]["default-definition"]["gowin-params"] == {
        "yosys-family": "",
        "nextpnr-family": "",
        "packer-device": "GW1N-1",
    }


def test_gowin_device_without_size_label_is_an_error(tmp_path):
    suite = fake_suite(tmp_path, ["GW9-99"])
    tables = {"GW9-99": {"GW9-LV99QN48C6/I5": ["QFN48", "GW9-99", "C6/I5"]}}
    with pytest.raises(pi.GeneratorError, match="GOWIN_SIZE"):
        pi.gowin_parts(suite, tables)


def test_ice40_offered_package_missing_from_the_chipdb_is_an_error(tmp_path):
    directory = tmp_path / "share/icebox"
    directory.mkdir(parents=True)
    (directory / "chipdb-384.txt").write_text(".device 384 8 10 8294\n.pins cm36\n")
    with pytest.raises(pi.GeneratorError, match="no chipdb for die|not in the"):
        pi.ice40_parts(tmp_path, [])


def test_suite_tag_reads_version_or_the_package_yosys_version(tmp_path):
    (tmp_path / "YOSYS-VERSION").write_text("20260927\n")
    assert pi.suite_tag(tmp_path) == "2026-09-27"
    (tmp_path / "YOSYS-VERSION").unlink()
    (tmp_path / "VERSION").write_text("20260324\n")
    assert pi.suite_tag(tmp_path) == "2026-03-24"
    (tmp_path / "VERSION").write_text("garbage")
    with pytest.raises(pi.GeneratorError):
        pi.suite_tag(tmp_path)
