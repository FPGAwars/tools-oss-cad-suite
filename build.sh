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

# -- Creating the package
# -- Copy templates/package-template.json
echo "--> Creating the package"
echo ""
PACKAGE_JSON="$PACKAGE_DIR"/"$ARCH"/package.json
cp -r "$WORK_DIR"/build-data/templates/package-template.json $PACKAGE_JSON

