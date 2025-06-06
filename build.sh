#!/bin/bash -x
#############################################
#      oss cad suite Apio package builder   #
#############################################

# Mac OSX Note:
# Install 7-zip and create for it a symling claled '7z':
#
#   brew install 7-zip
#   ln -s /opt/homebrew/bin/7zz /opt/homebrew/bin/7z

# -- Set the version the generated apio packages. This is
# -- also used to derive the release id.
VERSION=0.2.3

# -- The version of the upstream oss-cad-suite to use, specified
# -- as a date. See list here:
# -- https://github.com/YosysHQ/oss-cad-suite-build/releases
YEAR=2025
MONTH=05
DAY=26

# For debugging, echo executed commands.
# set -x

# Exit on any error
set -e

# Set english language for propper pattern matching
export LC_ALL=C

# -- Include the assertions.
source scripts/assertions.sh

# Generate tools-oss-cad-suite-arch-ver.tar.gz from the
# oss-cad-suite release file

# -- The name of the generated apio package. This typically does not
# -- need to be cahnged.
NAME=oss-cad-suite

#-- This version is stored in a temporal file so that
#-- github actions can read it and figure out the package
#-- name for upload it to the new release
echo "$VERSION" > "VERSION_BUILD"

# -- Base URL for oss-cad-suite package
SRC_URL_BASE="https://github.com/YosysHQ/oss-cad-suite-build/releases/download"

# -- Show the packaged version
echo "Package version: $VERSION"

# -- Target architectures
ARCH=$1
TARGET_ARCHS="linux_x86_64 linux_aarch64 windows_amd64 darwin darwin_arm64"

# -- Print the help message and exit
function print_help_exit {
  echo ""
  echo "Usage: bash build.sh ARCHITECTURE"
  echo ""
  echo "ARCHITECTURES: "
  echo "  * linux_x86_64  : Linux 64-bits"
  echo "  * linux_aarch64 : Linux ARM 64-bits"
  echo "  * windows_amd64 : Windows 64-bits"
  echo "  * darwin        : MAC x64"
  echo "  * darwin_arm64  : MAC arm64"
  echo ""
  echo "Example:"
  echo "bash build.sh linux_x86_64"
  echo ""
  exit 1
}

# ----------------------------------
# --- Check the Script parameters
# -----------------------------------

# --- There should be only one parameter
if [[ $# -gt 1 ]]; then
  echo ""
  echo "Error: too many arguments"
  print_help_exit
fi

# -- There sould be one parameter: The target architecture
# -- If no parameter, show an error message
if [[ $# -lt 1 ]]; then
  echo ""
  echo "Error: No target architecture given"
  print_help_exit
fi

# -- Check that the architectura name is correct
if [[ $ARCH =~ [[:space:]] || ! $TARGET_ARCHS =~ (^|[[:space:]])$ARCH([[:space:]]|$) ]]; then
  echo ""
  echo ">>> WRONG ARCHITECTURE \"$ARCH\""
  print_help_exit
fi

echo ""
echo "******* Building tools-$NAME apio package"
# echo ">>> ARCHITECTURE \"$ARCH\""
echo ""
echo "* ARCH:"
echo "  $ARCH"

# ---------------------------------------------------------------------
# - Create the folders to use for downloading the upstreams package
# - and creating the packages
# ---------------------------------------------------------------------

# -- Store the current dir
WORK_DIR=$PWD

# --  Folder for storing the upstream packages
UPSTREAM_DIR=$WORK_DIR/_upstream/$ARCH

# -- Folder for storing the generated packages
PACKAGE_DIR=$WORK_DIR/_packages/$ARCH

# -- Template folder
TEMPLATE="$WORK_DIR/templates/$ARCH"

# -- Create the upstream directory
mkdir -p "$UPSTREAM_DIR"

# -- Create the packages directory
mkdir -p $PACKAGE_DIR

echo ""
echo "* UPSTREAM DIR:"
echo "  $UPSTREAM_DIR"
echo ""
echo "* PACKAGE DIR:"
echo "  $PACKAGE_DIR"
echo ""

# ----------------------------------------------------------------------------
# -  Create variables from the INPUT parameters
# -

# -- Create the source architecture name of the source package
# --
# -- This is the table with the correspondence names of the architectures
#--  of the apio packages and the oss-cad-suite source package:
# --
# --  Apio package architecture    oss-cad-suite architecture
# --  -------------------------    --------------------------
# --     linux_x86_64               linux-x64
# --     linux_aarch64              linux-arm64
# --     windows_amd64              windows-x64
# --     darwin                     darwin-x64
# --     darwin_arm64               darwin-arm64

# --  if ARCH == linux_x86_64  --> ARCH_SRC = linux-x64
# --  if ARCH == linux_aarch64 --> ARCH_SRC = linux-arm64
# --  if ARCH == windows_amd64 --> ARCH_SRC = windows-x64
# --  if ARCH == darwin        --> ARCH_SRC = darwin-x64
# --  if ARCH == darwin_arm64  --> ARCH_SRC = darwin-arm64


if [ "${ARCH}" == "linux_x86_64" ]; then
   ARCH_SRC="linux-x64"
   EXT_SRC="tgz"
fi

if [ "${ARCH}" == "linux_aarch64" ]; then
   ARCH_SRC="linux-arm64"
   EXT_SRC="tgz"
fi

if [ "${ARCH}" == "windows_amd64" ]; then
   ARCH_SRC="windows-x64"
   EXT_SRC="exe"
fi

if [ "${ARCH}" == "darwin" ]; then
   ARCH_SRC="darwin-x64"
   EXT_SRC="tgz"
fi

if [ "${ARCH}" == "darwin_arm64" ]; then
   ARCH_SRC="darwin-arm64"
   EXT_SRC="tgz"
fi

# -- Create the UPSTREAM package name
# -- These are examples of oss-cad-suite package names for
# -- the different archs
# --
# -- Arquitecture   package name
# --  Linux-64:     oss-cad-suite-linux-x64-20210718.tgz
# --  Linux-arm64:  oss-cad-suite-linux-arm64-20210718.tgz
# --  Windows-64:   oss-cad-suite-windows-x64-20210718.exe
# --  MAC:          oss-cad-suite-darwin-x64-20210718.tgz

# -- Filename sintaxis:
# -- oss-cad-suite-<ARCH_SRC>-<YEAR><MONTH><DAY>.<EXT_SRC>

# -- Create the DATE tag
FILE_DATE=$YEAR$MONTH$DAY

# -- Upstream filename
FILENAME_SRC="oss-cad-suite-$ARCH_SRC-$FILE_DATE.$EXT_SRC"

echo "* Upstream package name:"
echo "  $FILENAME_SRC"
echo ""

# --------------------------------------------------
# ---- DOWNLOAD THE UPSTREAM oss-cad-suite PACKAGE
# --------------------------------------------------

# -- Create the complete URL for downloading the upstream package
# -- Example or URL:
# --   https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2021-07-18/oss-cad-suite-linux-x64-20210718.tgz
# --
# -- Sintax: <URL_BASE><RELEASE_DATE><FILENAME_SRC>
# --
RELEASE_TAG=$YEAR-$MONTH-$DAY
SRC_URL=$SRC_URL_BASE/$RELEASE_TAG/$FILENAME_SRC

echo "---> Downloading upstream OSS-CAD-SUITE package."
echo ""
echo "* URL: "
echo "  $SRC_URL"

# -- Change to the upstream folder
cd "$UPSTREAM_DIR"

# -- Download the source package (non verbose)
# -- If it has not already downloaded yet
test -e $FILENAME_SRC || wget -nv $SRC_URL

# --- Uncompress the upstream file
# --- if it has not already been done previously
echo ""
echo "---> Extracting the upstream OSS-CAD-SUITE package."

# -- On windows platforms we use 7z, as it is an self-extract .exe file
if [ "${ARCH:0:7}" == "windows" ]; then
  test -d oss-cad-suite || 7z x $FILENAME_SRC > /dev/null

else
  # -- tar for the other platforms
  test -d oss-cad-suite || tar vzxf $FILENAME_SRC > /dev/null
fi

# --------------------------------------------------------------------------
# -- CLEAN PACKED SUITE
# --------------------------------------------------------------------------
rm -f $FILENAME_SRC

# -----------------------------------------------------------
# -- Create the TARGET package
# -----------------------------------------------------------
PACKAGE_NAME=tools-oss-cad-suite-$ARCH-$VERSION.tar.gz
echo ""
echo "---> Copying upstream files to the target package"
echo ""
echo "* Target package:"
echo "  $PACKAGE_NAME"

# -- Create the folders of the target package
SOURCE_DIR=$UPSTREAM_DIR/oss-cad-suite

# --- Files to copy for the Linux x64 platforms
if [ "$ARCH" == "linux_x86_64" ]; then

  source "$WORK_DIR"/scripts/install_linux_x64.sh
fi

# --- Files to copy for the Linux ARM-64 platforms
if [ "$ARCH" == "linux_aarch64" ]; then

  source "$WORK_DIR"/scripts/install_linux_arm64.sh
fi

# --- Files to copy for the MAC platforms
if [ "$ARCH" == "darwin" ]; then

  source "$WORK_DIR"/scripts/install_darwin.sh
fi

# --- Files to copy for the MAC platforms
if [ "$ARCH" == "darwin_arm64" ]; then

  source "$WORK_DIR"/scripts/install_darwin_arm64.sh
fi

# --- Files to copy for the WINDOWS platforms
if [ "$ARCH" == "windows_amd64" ]; then

  source "$WORK_DIR"/scripts/install_windows_x64.sh
fi

# -----------------------------------------------------------
# -- Set package version.
# -----------------------------------------------------------
echo ""
echo "---> Setting target package metadata."

# -- Copy templates/package-template.json and fill-in version and arch.
# -- Using in-place flag with an actual ".bak" suffix for OSX compatibilty.
PACKAGE_JSON="$PACKAGE_DIR"/package.json
cp -r "$WORK_DIR"/build-data/templates/package-template.json $PACKAGE_JSON
sed -i.bak "s/%VERSION%/\"$VERSION\"/;" $PACKAGE_JSON
sed -i.bak "s/%SYSTEM%/\"$ARCH\"/;" $PACKAGE_JSON
rm ${PACKAGE_JSON}.bak

echo ""
echo "---> Compressing the target package."
cd $PACKAGE_DIR
tar zcf ../$PACKAGE_NAME ./*

echo ""
echo "---> Cleaning work files."
cd $WORK_DIR
rm -rf $UPSTREAM_DIR
rm -rf $PACKAGE_DIR

echo ""
echo "---> Package created: $PACKAGE_NAME"
