#!/bin/bash
#############################################
#      oss cad suite Apio package builder   #
#############################################

# Set english language for propper pattern matching
export LC_ALL=C

# Generate tools-oss-cad-suite-arch-ver.tar.gz from the  
# oss-cad-suite release file



#-----------------------------------------------------------

# -- Tool name
NAME=oss-cad-suite
VERSION=0.0.1

YEAR=2021
MONTH=06
DAY=27
RELEASE_TAG=$YEAR-$MONTH-$DAY
FILE_TAG=$YEAR$MONTH$DAY
ARCH="linux-x64"
EXT="tgz"

URL_BASE="https://github.com/YosysHQ/oss-cad-suite-build/releases/download"
FILENAME_SRC="oss-cad-suite-$ARCH-$FILE_TAG.$EXT"
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
test -e $FILENAME_SRC || wget $URL

# --- Uncompress the release file
echo "--> Extracting the upstream package"
echo ""
test -d oss-cad-suite || tar vzxf $FILENAME_SRC

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
tar vzcf ../tools-oss-cad-suite-$ARCH-$FILE_TAG.tar.gz ./*
echo "--> Package created: tools-oss-cad-suite-$ARCH-$VERSION.tar.gz"
