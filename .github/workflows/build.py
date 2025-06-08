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
from pathlib import Path

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


def darwin_x86_64_packager(yosys_dir: Path, package_dir: Path) -> None:
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


def linux_aarch64_packager(yosys_dir: Path, package_dir: Path) -> None:
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


def get_platform_info(platform_id: str, yosys_package_tag: str) -> PlatformInfo:
    """Extract (platform_id, platform_info)"""

    # platform_id = build_info["target-platform"]

    # -- Maps apio platform codes to their attributes.
    PLATFORMS = {
        "darwin-arm64": PlatformInfo(
            f"oss-cad-suite-darwin-arm64-{yosys_package_tag}.tgz",
            ["tar", "zxf"],
            darwin_arm64_packager,
        ),
        "darwin-x86-64": PlatformInfo(
            f"oss-cad-suite-darwin-x64-{yosys_package_tag}.tgz",
            ["tar", "zxf"],
            darwin_x86_64_packager,
        ),
        "linux-x86-64": PlatformInfo(
            f"oss-cad-suite-linux-x64-{yosys_package_tag}.tgz",
            ["tar", "zxf"],
            linux_x86_64_packager,
        ),
        "linux-aarch64": PlatformInfo(
            f"oss-cad-suite-linux-arm64-{yosys_package_tag}.tgz",
            ["tar", "zxf"],
            linux_aarch64_packager,
        ),
        "windows-amd64": PlatformInfo(
            f"oss-cad-suite-windows-x64-{yosys_package_tag}.exe",
            ["7z", "x"],
            windows_amd64_packager,
        ),
    }

    return PLATFORMS[platform_id]


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
        ".tar.gz",
    ]
    package_filename = "".join(parts)
    print(f"\n{package_filename=}")
    build_info["file-name"] = package_filename

    # -- Construct Yosys URL
    parts = [
        "https://github.com/YosysHQ/oss-cad-suite-build/releases/download",
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

    # Write updated build info to the package
    print("Writing package build info.")
    output_json_file = package_dir / "build-info.json"
    with output_json_file.open("w", encoding="utf-8") as f:
        json.dump(build_info, f, indent=2)
        f.write("\n")  # Ensure the file ends with a newline
    run(["ls", "-al", package_dir])
    run(["cat", "-n", output_json_file])

    # Format the json file in the package dir
    print("Formatting package build info.")
    run(["json-align", "--in-place", "--spaces", "2", output_json_file])
    run(["ls", "-al", package_dir])
    run(["cat", "-n", output_json_file])

    # -- Compress the package. We run it in the shell for '*" to expand.
    print("Compressing the  package.")
    os.chdir(package_dir)
    run(f"tar zcf ../{package_filename} ./*", shell=True)

    # -- Delete the package dir (large)
    print(f"\nDeleting package dir {package_dir}")
    shutil.rmtree(package_dir)

    # -- Final check, at the repo root which is common
    # -- to all the platforms.
    os.chdir(work_dir)  #
    print(f"\n{Path.cwd()=}")
    run(["ls", "-al"])
    run(["ls", "-al", "_packages"])
    assert (Path("_packages") / package_filename).is_file()

    # -- All done


if __name__ == "__main__":
    main()
