"""A Python script to build the oss-cad-suite package for a given platform"""

# This script is called from the github build workflow and and runs
# in the top dir of this repo. it uses ./_upstream and ./_packages
# directories for input and output files respectively.
#
# To install 7z on mac:
#   brew install p7zip

import os
import json
import subprocess
from dataclasses import dataclass
from typing import List, Callable, Union, Dict, Tuple
import argparse
import shutil
import tarfile
import urllib.error
import urllib.request
from pathlib import Path

import parts_indexes

# -- Command line options.
parser = argparse.ArgumentParser()


# The platform id. E.g. "darwin-arm64"
parser.add_argument("--platform_id", required=True, type=str, help="Platform to build")


# Path to the properties file with the build info.
parser.add_argument(
    "--build-info-json", required=True, type=str, help="JSON with build properties"
)

args = parser.parse_args()


def run(cmd_args: Union[List[str], str], shell: bool = False) -> None:
    """Run a command and check that it succeeded. Select shell=true to enable
    shell features such as '*' glob."""
    print(f"\nRun: {cmd_args}")
    print(f"{shell=}", flush=True)
    subprocess.run(cmd_args, check=True, shell=shell)
    print("Run done\n", flush=True)


def rsync_yosys_package(yosys_dir: Path, package_dir: Path) -> None:
    """Copy yosys package files to the destination package."""

    # -- Check that yosys dir is not empty and package dir is.
    assert any(yosys_dir.iterdir())
    assert not any(package_dir.iterdir())

    # -- Copy the package directory tree. We avoid 'cp' because it copies
    # -- symlinks as files and inflates the package.
    # -- The flag 'q' is for 'quiet'.
    run(["rsync", "-aq", f"{yosys_dir}/", f"{package_dir}/"])

    # -- Rename VERSION to YOSYS-VERSION
    (package_dir / "VERSION").rename(package_dir / "YOSYS-VERSION")


def check_package_executables(package_dir: Path, executables: List[str]) -> None:
    """Check that a few binaries exists and are executable."""
    for bin_file in executables:
        file_path = package_dir / bin_file
        print(f"Checking executable: {file_path}")
        assert file_path.is_file(), file_path
        assert os.access(file_path, os.X_OK), file_path


def darwin_arm64_packager(yosys_dir: Path, package_dir: Path) -> None:
    """Copy the files from yosys dir to our package dir."""

    # -- Copy files.
    rsync_yosys_package(yosys_dir, package_dir)

    # -- Check that a few binaries exists and are executable..
    check_package_executables(
        package_dir,
        [
            "bin/yosys",
            "bin/nextpnr-ice40",
            "bin/nextpnr-ecp5",
            "bin/nextpnr-himbaechel",
            "bin/dot",
            "bin/gtkwave",
        ],
    )

    # Check that the libusb backend exists. We use it to list USB devices.
    assert (package_dir / "lib/libusb-1.0.0.dylib").is_file()


def linux_x86_64_packager(yosys_dir: Path, package_dir: Path) -> None:
    """Copy the files from yosys dir to our package dir."""

    # -- Copy files.
    rsync_yosys_package(yosys_dir, package_dir)

    # -- Check that a few binaries exists and are executable..
    check_package_executables(
        package_dir,
        [
            "bin/yosys",
            "bin/nextpnr-ice40",
            "bin/nextpnr-ecp5",
            "bin/nextpnr-himbaechel",
            "bin/dot",
            "bin/gtkwave",
        ],
    )

    # Check that the libusb backend exists. We use it to list USB devices.
    assert (package_dir / "lib/libusb-1.0.so.0").is_file()

    # Check that the libusb backend exists. We use it to list USB devices.
    assert (package_dir / "lib/libusb-1.0.so.0").is_file()


def windows_amd64_packager(yosys_dir: Path, package_dir: Path) -> None:
    """Copy the files from yosys dir to our package dir."""

    # -- Copy files.
    rsync_yosys_package(yosys_dir, package_dir)

    # -- Check that a few binaries exists and are executable..
    check_package_executables(
        package_dir,
        [
            "bin/yosys.exe",
            "bin/nextpnr-ice40.exe",
            "bin/nextpnr-ecp5.exe",
            "bin/nextpnr-himbaechel.exe",
            "bin/gtkwave.exe",
        ],
    )

    # Check that the libusb backend exists. We use it to list USB devices.
    assert (package_dir / "lib/libusb-1.0.dll").is_file()


@dataclass(frozen=True)
class PlatformInfo:
    """Represents the properties of a platform."""

    yosys_fname: str
    unarchive_cmd: List[str]
    packager_function: Callable[[Path, Path], None]


YOSYS_RELEASES_URL = "https://github.com/YosysHQ/oss-cad-suite-build/releases/download"


def url_exists(url: str) -> bool:
    """True if a HEAD request to the url succeeds, False on a 404. Any other
    failure is raised, so a network problem is not mistaken for a missing
    asset."""
    request = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(request, timeout=60):
            return True
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False
        raise


def get_windows_platform_info(yosys_package_tag: str) -> PlatformInfo:
    """YosysHQ published the windows suite as a self-extracting .exe (opened
    with 7z) up to release 2026-03-24 and as a .tgz from 2026-09-27 on. Instead
    of hardcoding a cutoff date, ask the release which one it carries: the .tgz
    if it exists, otherwise the .exe."""
    t = yosys_package_tag
    release_tag = f"{t[:4]}-{t[4:6]}-{t[6:]}"
    base = f"oss-cad-suite-windows-x64-{yosys_package_tag}"
    if url_exists(f"{YOSYS_RELEASES_URL}/{release_tag}/{base}.tgz"):
        print(f"Windows asset of {release_tag}: {base}.tgz (tar)")
        return PlatformInfo(f"{base}.tgz", ["tar", "zxf"], windows_amd64_packager)
    print(f"Windows asset of {release_tag}: {base}.exe (7z)")
    return PlatformInfo(f"{base}.exe", ["7z", "x"], windows_amd64_packager)


def get_platform_info(platform_id: str, yosys_package_tag: str) -> PlatformInfo:
    """Extract (platform_id, platform_info)"""

    # -- Maps apio platform codes to their attributes.
    PLATFORMS = {
        "darwin-arm64": PlatformInfo(
            f"oss-cad-suite-darwin-arm64-{yosys_package_tag}.tgz",
            ["tar", "zxf"],
            darwin_arm64_packager,
        ),
        "linux-x86-64": PlatformInfo(
            f"oss-cad-suite-linux-x64-{yosys_package_tag}.tgz",
            ["tar", "zxf"],
            linux_x86_64_packager,
        ),
    }

    # -- The windows asset depends on the release, so it is resolved (with a
    # -- request) only when building windows.
    if platform_id == "windows-amd64":
        return get_windows_platform_info(yosys_package_tag)

    return PLATFORMS[platform_id]


# -- The platform whose tree the parts indexes are generated from, and the
# -- staging dir (under _packages/) where they wait for the other platforms.
PARTS_INDEXES_PLATFORM = "linux-x86-64"
PARTS_INDEXES_STAGING = "parts-indexes"
DB_HASHES_FILE = "database-hashes.json"


def attach_parts_indexes(
    platform_id: str, package_dir: Path, work_dir: Path, build_info: Dict
) -> None:
    """Puts the four <ARCH>-PARTS-INDEX.json documents at the root of the
    package.

    The documents are generated once, from the linux tree (the only one whose
    interpreter can run on the ubuntu runner, so the workflow builds linux
    first), and copied to every platform. That is only sound if the databases
    they are generated from are identical on all platforms, which is checked
    here for each of them (the files are hashed, see
    parts_indexes.database_hashes)."""

    staging = work_dir / "_packages" / PARTS_INDEXES_STAGING
    hashes = parts_indexes.database_hashes(package_dir)
    assert hashes, f"No databases found in {package_dir}"

    if platform_id == PARTS_INDEXES_PLATFORM:
        print("\nGenerating the parts indexes.")
        docs, warnings = parts_indexes.generate(package_dir, build_info)
        parts_indexes.check_no_collisions(docs)
        for warning in warnings:
            print(f"WARNING: {warning}")
        shutil.rmtree(staging, ignore_errors=True)
        parts_indexes.write_documents(docs, staging)
        with (staging / DB_HASHES_FILE).open("w", encoding="utf-8") as f:
            json.dump(hashes, f, indent=2, sort_keys=True)
            f.write("\n")
    else:
        assert (staging / DB_HASHES_FILE).is_file(), (
            f"The parts indexes are generated when the {PARTS_INDEXES_PLATFORM} "
            "package is built, which must come first in the workflow."
        )
        with (staging / DB_HASHES_FILE).open("r", encoding="utf-8") as f:
            reference = json.load(f)
        different = sorted(
            key
            for key in reference.keys() | hashes.keys()
            if reference.get(key) != hashes.get(key)
        )
        assert not different, (
            f"The databases of {platform_id} differ from those of "
            f"{PARTS_INDEXES_PLATFORM}: {different}"
        )

    for arch in parts_indexes.ARCHS:
        name = f"{arch.upper()}-PARTS-INDEX.json"
        assert (staging / name).is_file(), staging / name
        shutil.copy2(staging / name, package_dir / name)
        print(f"Added {name} to the package.")


def check_package_has_parts_indexes(package_file: Path) -> None:
    """Checks that the compressed package carries the four documents at its
    root."""
    expected = {f"./{arch.upper()}-PARTS-INDEX.json" for arch in parts_indexes.ARCHS}
    with tarfile.open(package_file, "r:gz") as tar:
        names = {info.name for info in tar}
    missing = expected - names
    assert not missing, f"{package_file} lacks {sorted(missing)}"


def main():
    """Builds the Apio oss-cad-suite package for one platform."""

    # -- Save the start dir. It is assume to be at top of this repo.
    work_dir: Path = Path.cwd()
    print(f"\n{work_dir=}")

    # -- Get platform id.
    platform_id = args.platform_id
    print(f"{platform_id=}")

    # -- Get the build info
    with Path(args.build_info_json).open("r", encoding="utf-8") as f:
        build_info = json.load(f)

    print("\nOriginal build info:")
    print(json.dumps(build_info, indent=2))

    # -- Extract build info params
    release_tag = build_info["release-tag"]
    package_tag = release_tag.replace("-", "")
    yosys_release_tag = build_info["yosys-release-tag"]
    yosys_package_tag = yosys_release_tag.replace("-", "")
    platform_info = get_platform_info(platform_id, yosys_package_tag)

    print()
    print(f"* {platform_id=}")
    print(f"* {release_tag=}")
    print(f"* {package_tag=}")
    print(f"* {platform_info=}")
    print(f"* {yosys_release_tag=}")
    print(f"* {yosys_package_tag=}")

    # --  Create a folder for storing the upstream packages
    upstream_dir: Path = work_dir / "_upstream" / platform_id
    print(f"\n{upstream_dir=}")
    upstream_dir.mkdir(parents=True, exist_ok=True)

    # -- Create a folder for storing the generated package file.
    package_dir: Path = work_dir / "_packages" / platform_id
    print(f"\n{package_dir=}")
    package_dir.mkdir(parents=True, exist_ok=True)

    # -- Construct target package file name
    parts = [
        "apio-oss-cad-suite",
        "-",
        platform_id,
        "-",
        package_tag,
        ".tgz",
    ]
    package_filename = "".join(parts)
    print(f"\n{package_filename=}")

    # Extend build info
    build_info["target-platform"] = platform_id
    build_info["file-name"] = package_filename

    # -- Construct Yosys URL
    parts = [
        YOSYS_RELEASES_URL,
        "/",
        yosys_release_tag,
        "/",
        platform_info.yosys_fname,
    ]
    yosys_url = "".join(parts)
    print(f"\n{yosys_url=}")

    # --  Change to the upstream dir.
    print(f"\nChanging to UPSTREAM_DIR: {str(upstream_dir)}")
    os.chdir(upstream_dir)

    # -- Download the Yosys file.
    print(f"\nDownloading {yosys_url}")
    run(["wget", "-nv", yosys_url])
    run(["ls", "-al"])

    # -- Uncompress the yosys archive
    print("Uncompressing the Yosys file")
    run(platform_info.unarchive_cmd + [platform_info.yosys_fname])
    run(["ls", "-al"])

    # -- Delete the Yosys archive (large).
    print("Deleting the Yosys archive file")
    Path(platform_info.yosys_fname).unlink()
    run(["ls", "-al"])

    # -- Call the packager function to copy files from the yosys
    # -- dir to the output package dir.
    print(f"\nCalling packager function {platform_info.packager_function}")
    print(f"  Source dir: {upstream_dir / 'oss-cad-suite'}")
    print(f"  Dest dir:   {package_dir}")
    platform_info.packager_function(upstream_dir / "oss-cad-suite", package_dir)

    # -- Add the parts indexes (same documents on every platform).
    attach_parts_indexes(platform_id, package_dir, work_dir, build_info)

    # Write updated build info to the package
    print("Writing package build info.")
    output_json_file = package_dir / "BUILD-INFO.json"
    with output_json_file.open("w", encoding="utf-8") as f:
        json.dump(build_info, f, indent=2)
        f.write("\n")  # Ensure the file ends with a newline
    run(["cat", "-n", output_json_file])

    # Format the json file in the package dir
    print("Formatting package build info.")
    run(["json-align", "--in-place", "--spaces", "2", output_json_file])
    run(["cat", "-n", output_json_file])

    # -- Compress the package. We run it in the shell for '*" to expand.
    print("Compressing the  package.")
    os.chdir(package_dir)
    run(f"tar zcf ../{package_filename} ./*", shell=True)
    check_package_has_parts_indexes(package_dir.parent / package_filename)

    # -- Delete the package dir (large)
    print(f"\nDeleting package dir {package_dir}")
    os.chdir(work_dir)
    shutil.rmtree(package_dir)

    # -- Final check, at the repo root which is common
    # -- to all the platforms.
    os.chdir(work_dir)
    print(f"\n{Path.cwd()=}")
    run(["ls", "-al"])
    run(["ls", "-al", "_packages"])
    assert (Path("_packages") / package_filename).is_file()

    # -- All done


if __name__ == "__main__":
    main()
