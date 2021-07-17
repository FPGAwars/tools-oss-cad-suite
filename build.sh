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
YEAR=2021
MONTH=06
DAY=27

# -- Target package version: Read from the VERSION text file
# -- Set the version in that file first
VERSION=$(cat VERSION)
echo "Package version: $VERSION"

# -- Target architectures
ARCH=$1
TARGET_ARCHS="linux_x86_64 windows_amd64 darwin"

# -- Print the help message and exit
function print_help_exit {
  echo ""
  echo "Usage: bash build.sh ARCHITECTURE"
  echo ""
  echo "ARCHITECTURES: "
  echo "  * linux_x86_64  : Linux 64-bits"
  echo "  * windows_amd64 : Windows 64-bits"
  echo "  * darwin        : MAC"
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
# --     windows_amd64              windows-x64
# --     darwin                     darwin-x64

# --  if ARCH == linux_x86_64  --> ARCH_SRC = linux-x64
# --  if ARCH == windows_amd64 --> ARCH_SRC = windows-x64
# --  if ARCH == darwin ---> ARCH_SRC = darwin-x64

if [ "${ARCH}" == "linux_x86_64" ]; then
   ARCH_SRC="linux-x64"
fi

if [ "${ARCH}" == "windows_amd64" ]; then
   ARCH_SRC="windows-x64"
fi

if [ "${ARCH}" == "darwin" ]; then
   ARCH_SRC="darwin-x64"
fi

echo "Src architecture: $ARCH_SRC"

exit 1

RELEASE_TAG=$YEAR-$MONTH-$DAY
FILE_TAG=$YEAR$MONTH$DAY
EXT="tgz"

PACKAGE_NAME=tools-oss-cad-suite-$ARCH-$VERSION.tar.gz

URL_BASE="https://github.com/YosysHQ/oss-cad-suite-build/releases/download"
FILENAME_SRC="oss-cad-suite-$ARCH_SRC-$FILE_TAG.$EXT"
URL=$URL_BASE/$RELEASE_TAG/$FILENAME_SRC

TOOL_SYSTEM_VERSION=1.1.2
TOOL_SYSTEM_URL_BASE=https://github.com/FPGAwars/tools-system/releases/download/v$TOOL_SYSTEM_VERSION
TOOL_SYSTEM_ARCH=linux_x86_64
TOOL_SYSTEM_TAR="tools-system-$TOOL_SYSTEM_ARCH-$TOOL_SYSTEM_VERSION.tar.gz"
TOOL_SYSTEM_URL=$TOOL_SYSTEM_URL_BASE/$TOOL_SYSTEM_TAR

# -- Store current dir
WORK_DIR=$PWD

# --  Folder for storing the upstream packages
UPSTREAM_DIR=$WORK_DIR/_upstream
# -- Folder for storing the generated packages
PACKAGE_DIR=$WORK_DIR/_packages

# -- Create the upstream directory and enter into it
mkdir -p "$UPSTREAM_DIR"
# -- Create the packages directory
mkdir -p $PACKAGE_DIR/$ARCH

# -- Download the release packages if it has not already
# -- been downloaded previously
echo "---> Download upstream package: "
echo "URL: $UPSTREAM_DIR"
echo "FILE: $FILENAME_SRC"
echo ""
cd "$UPSTREAM_DIR"
# -- Download the source package (non verbose)
test -e $FILENAME_SRC || wget -nv $URL

# --- Uncompress the release file
echo "--> Extracting the upstream package"
echo ""
test -d oss-cad-suite || tar vzxf $FILENAME_SRC > /dev/null

# -- Create the folders of the target package
TARGET_DIR=$PACKAGE_DIR/$ARCH
SOURCE_DIR=$UPSTREAM_DIR/oss-cad-suite

mkdir -p $TARGET_DIR/bin
mkdir -p $TARGET_DIR/lib
mkdir -p $TARGET_DIR/libexec

# -- Copy the selected files to the target dir
echo "--> Copying files"
echo ""
install $SOURCE_DIR/bin/lsusb $TARGET_DIR/bin
install $SOURCE_DIR/bin/lsftdi $TARGET_DIR/bin
install $SOURCE_DIR/lib/ld-linux-x86-64.so.2 $TARGET_DIR/lib
install $SOURCE_DIR/lib/libc.so.6 $TARGET_DIR/lib
install $SOURCE_DIR/lib/libftdi1.so.2 $TARGET_DIR/lib
install $SOURCE_DIR/libexec/lsusb $TARGET_DIR/libexec
install $SOURCE_DIR/libexec/lsftdi $TARGET_DIR/libexec

# -- Download the tools-system package
# -- (for getting the eeprom-ftdi executable)
# -- (not available in the oss-cad-suite)
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

# -- Copy the ftdi_eeprom file
install bin/ftdi_eeprom $TARGET_DIR/bin

# -- Creating the package
# -- Copy templates/package-template.json
echo "--> Creating the package"
echo ""
PACKAGE_JSON="$PACKAGE_DIR"/"$ARCH"/package.json
cp -r "$WORK_DIR"/build-data/templates/package-template.json $PACKAGE_JSON
echo "ARCH: $ARCH"
if [ "$ARCH" == "linux-x64" ]; then
  sed -i "s/%VERSION%/\"$VERSION\"/;" "$PACKAGE_DIR"/"$ARCH"/package.json
  sed -i "s/%SYSTEM%/\"linux_x86_64\"/;" "$PACKAGE_DIR"/"$ARCH"/package.json
fi
cd $PACKAGE_DIR/$ARCH

tar vzcf ../$PACKAGE_NAME ./* 
echo "--> Package created: $PACKAGE_NAME"

