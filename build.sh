#!/bin/bash
#############################################
#      oss cad suite Apio package builder   #
#############################################

# Set english language for propper pattern matching
export LC_ALL=C

# Generate tools-oss-cad-suite-arch-ver.tar.gz from the  
# oss-cad-suite release file



#-----------------------------------------------------------
# -- INPUT parameters
#
# -- Tool name
NAME=oss-cad-suite

# -- DATE. It is used for getting the oss-cad-suite source package
# -- If you want to genete an updated oss-cad-suite apio packages
# -- set the new date
YEAR=2024
MONTH=01
DAY=19

# -- Set the version for the new package
VERSION=0.1.0

#-- This version is stored in a temporal file so that
#-- github actions can read it and figure out the package
#-- name for upload it to the new release
echo "$VERSION" > "VERSION_BUILD"

# -- Base URL for oss-cad-suite package
SRC_URL_BASE="https://github.com/YosysHQ/oss-cad-suite-build/releases/download"

# -- Show the packaged version
echo "Package version: $VERSION"

# -- Version of the tool-system package
# -- This tool is were the ftdi-eeprom program is stored
TOOL_SYSTEM_VERSION=1.1.2

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
echo ">>> ARCHITECTURE \"$ARCH\""
echo ""

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
# --  if ARCH == darwin ---> ARCH_SRC = darwin-x64
# --  if ARCH == darwin_arm64 ---> ARCH_SRC = darwin-arm64


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

echo "> Upstream package name:"
echo "  $FILENAME_SRC"
echo ""

# -- Create the complete URL for downloading the upstream package
# -- Example or URL:
# --   https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2021-07-18/oss-cad-suite-linux-x64-20210718.tgz
# --   
# -- Sintax: <URL_BASE><RELEASE_DATE><FILENAME_SRC>
# --
RELEASE_TAG=$YEAR-$MONTH-$DAY
SRC_URL=$SRC_URL_BASE/$RELEASE_TAG/$FILENAME_SRC

echo "---> DOWNLOADING UPSTREAM PACKAGES"
echo "* URL: "
echo "  $SRC_URL"
echo ""

# --------------------------------------------------
# ---- DOWNLOAD THE UPSTREAM oss-cad-suite PACKAGE
# --------------------------------------------------

# -- Change to the upstream folder
cd "$UPSTREAM_DIR"

# -- Download the source package (non verbose)
# -- If it has not already downloaded yet
test -e $FILENAME_SRC || wget -nv $SRC_URL

# --- Uncompress the upstream file
# --- if it has not already been done previously
echo "---> EXTRACTING the upstream package"
echo ""

# -- On windows platforms we use 7z, as it is an self-extract .exe file
if [ "${ARCH:0:7}" == "windows" ]; then
  test -d oss-cad-suite || 7z x $FILENAME_SRC > /dev/null

else
  # -- tar for the other platforms
  test -d oss-cad-suite || tar vzxf $FILENAME_SRC > /dev/null
fi

# -------------------------------------------------------
# -- DOWNLOAD the TOOL-SYSTEM package
# -------------------------------------------------------
# -- (for getting the eeprom-ftdi executable)
# -- (not available in the oss-cad-suite)
# -- (Not avaialbe for arm-64)

if [ "${ARCH}" == "darwin_arm64" ]; then
  echo ""
  echo "---> OSX ARM 64 HAS NOT TOOL-SYSTEM PACKAGE"
  echo ""

else
  TOOL_SYSTEM_URL_BASE=https://github.com/FPGAwars/tools-system/releases/download/v$TOOL_SYSTEM_VERSION
  TOOL_SYSTEM_TAR="tools-system-$ARCH-$TOOL_SYSTEM_VERSION.tar.gz"
  TOOL_SYSTEM_URL=$TOOL_SYSTEM_URL_BASE/$TOOL_SYSTEM_TAR
  TOOL_SYSTEM_SRC="$UPSTREAM_DIR/tools-system"

  echo "---> DOWNLOADING the TOOL-SYSTEM Package"
  echo "* Package:" 
  echo "  $TOOL_SYSTEM_TAR"
  echo "* URL: "
  echo "  $TOOL_SYSTEM_URL"
  echo ""

  # -- Download the tools-system package
  # -- If it has already been downloaded yet

  echo "--> Download tool-system package"
  echo ""
  cd "$UPSTREAM_DIR"
  mkdir -p tools-system
  cd tools-system
  test -e $TOOL_SYSTEM_TAR || wget $TOOL_SYSTEM_URL

  # -- Extract the tools-system package
  echo "--> Extracting the tool-system package"
  echo ""
  test -d bin || tar vzxf $TOOL_SYSTEM_TAR

fi
# -----------------------------------------------------------
# -- Create the TARGET package
# -----------------------------------------------------------
PACKAGE_NAME=tools-oss-cad-suite-$ARCH-$VERSION.tar.gz
echo ""
echo "---> CREATE THE TARGET PACKAGE"
echo ""
echo "* Package:"
echo "  $PACKAGE_NAME"
echo ""

# -- Create the folders of the target package
SOURCE_DIR=$UPSTREAM_DIR/oss-cad-suite

mkdir -p $PACKAGE_DIR/bin
mkdir -p $PACKAGE_DIR/lib
mkdir -p $PACKAGE_DIR/libexec

# -------------------------------------------------------
# - Copy the files to be included in the package
# - The files depend on the platform
#-------------------------------------------------------

# -- Copy the selected files to the target dir
echo "--> Copying files"
echo ""

# --- Files to copy for the Linux x64 platforms
if [ "$ARCH" == "linux_x86_64" ]; then

  . "$WORK_DIR"/scripts/install_linux_x64.sh
fi

# --- Files to copy for the Linux ARM-64 platforms
if [ "$ARCH" == "linux_aarch64" ]; then

  . "$WORK_DIR"/scripts/install_linux_arm64.sh
fi


# --- Files to copy for the MAC platforms
if [ "$ARCH" == "darwin" ]; then

  . "$WORK_DIR"/scripts/install_darwin.sh
fi

# --- Files to copy for the MAC platforms
if [ "$ARCH" == "darwin_arm64" ]; then

  . "$WORK_DIR"/scripts/install_darwin_arm64.sh
fi



# --- Files to copy for the WINDOWS platforms
if [ "$ARCH" == "windows_amd64" ]; then

  . "$WORK_DIR"/scripts/install_windows_x64.sh  
fi

# -- Debug: Stop here!
#exit 1

# -----------------------------------------------------------
# -- Create the TARGET package
# -----------------------------------------------------------
echo ""
echo "---> CREATE THE TARGET PACKAGE"
echo ""

# -- Copy templates/package-template.json
echo ""
PACKAGE_JSON="$PACKAGE_DIR"/package.json
cp -r "$WORK_DIR"/build-data/templates/package-template.json $PACKAGE_JSON
sed -i "s/%VERSION%/\"$VERSION\"/;" "$PACKAGE_DIR"/package.json
sed -i "s/%SYSTEM%/\"$ARCH\"/;" "$PACKAGE_DIR"/package.json

cd $PACKAGE_DIR

tar zcf ../$PACKAGE_NAME ./* 
echo "--> Package created: $PACKAGE_NAME"