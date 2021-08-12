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

# -- Base URL for oss-cad-suite package
SRC_URL_BASE="https://github.com/YosysHQ/oss-cad-suite-build/releases/download"

# -- Target package version: Read from the VERSION text file
# -- Set the version in that file first
VERSION=$(cat VERSION)
echo "Package version: $VERSION"

# -- Version of the tool-system package
# -- This tool is were the ftdi-eeprom program is stored
TOOL_SYSTEM_VERSION=1.1.2

# -- Target architectures
ARCH=$1
TARGET_ARCHS="linux_x86_64 linux_aarch64 windows_amd64 darwin"

# -- Print the help message and exit
function print_help_exit {
  echo ""
  echo "Usage: bash build.sh ARCHITECTURE"
  echo ""
  echo "ARCHITECTURES: "
  echo "  * linux_x86_64  : Linux 64-bits"
  echo "  * linux_aarch64 : Linux ARM 64-bits"
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

# --  if ARCH == linux_x86_64  --> ARCH_SRC = linux-x64
# --  if ARCH == linux_aarch64 --> ARCH_SRC = linux-arm64
# --  if ARCH == windows_amd64 --> ARCH_SRC = windows-x64
# --  if ARCH == darwin ---> ARCH_SRC = darwin-x64


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

# -- Copy the selected files to the target dir
echo "--> Copying files"
echo ""

# -- The executable files ends in .exe on Windows platforms

# -- On windows platforms we use 7z, as it is an self-extract .exe file
if [ "${ARCH:0:7}" == "windows" ]; then
  EXE=".exe"

else
  # -- No exe extension for the other platoforms
  EXE=""
fi


# --- Files to copy for the Linux x64 platforms
if [ "$ARCH" == "linux_x86_64" ]; then

  echo "* Copying Linux files..."
  echo ""
  # --------------------
  # -- System tools
  # --------------------

  # -- Executables
  install $SOURCE_DIR/bin/lsusb $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/lsftdi $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/lsusb $PACKAGE_DIR/libexec
  install $SOURCE_DIR/libexec/lsftdi $PACKAGE_DIR/libexec

  # -- Copy the ftdi_eeprom file
  install $TOOL_SYSTEM_SRC/bin/ftdi_eeprom $PACKAGE_DIR/bin

  # -- Libraries
  install $SOURCE_DIR/lib/ld-linux-x86-64.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libc.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libudev.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpthread.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/librt.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libusb-1.0.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libftdi1.so* $PACKAGE_DIR/lib
  

  # ---------------------------
  # -- Iceprog
  # ---------------------------
  # -- Executable
  install $SOURCE_DIR/bin/iceprog $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/iceprog $PACKAGE_DIR/libexec
  

  # ----------------------------
  # -- YOSYS
  # ----------------------------
  # -- Executables
  install $SOURCE_DIR/bin/yosys $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/yosys $PACKAGE_DIR/libexec
  install $SOURCE_DIR/bin/yosys-abc $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/yosys-abc $PACKAGE_DIR/libexec

  # -- Libraries
  install $SOURCE_DIR/lib/libstdc++.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libm.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libreadline.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libffi.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libdl.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libz.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libtcl* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libgcc_s.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libtinfo.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/yosys-abc $PACKAGE_DIR/lib

  # -- Share
  mkdir -p $PACKAGE_DIR/share/yosys
  cp -r $SOURCE_DIR/share/yosys/* $PACKAGE_DIR/share/yosys

  #------------------------------------------
  #-- ICE40 tools
  #------------------------------------------
  # -- Executable
  install $SOURCE_DIR/bin/icebram $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/icebram $PACKAGE_DIR/libexec
  install $SOURCE_DIR/bin/icemulti $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/icemulti $PACKAGE_DIR/libexec
  install $SOURCE_DIR/bin/icepack $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/icepack $PACKAGE_DIR/libexec
  install $SOURCE_DIR/bin/icepll $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/icepll $PACKAGE_DIR/libexec
  install $SOURCE_DIR/bin/icetime $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/icetime $PACKAGE_DIR/libexec

 # -- Share
  mkdir -p $PACKAGE_DIR/share/icebox
  cp -r $SOURCE_DIR/share/icebox/* $PACKAGE_DIR/share/icebox

  # -----------------------------------
  # -- NETXPNR-ICE40
  # -----------------------------------
  # -- Executable
  # -- It is copied from the template
  # -- It is a simplified version of the one provided by
  # -- the oss-cad-suite
  install $TEMPLATE/nextpnr-ice40 $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/nextpnr-ice40 $PACKAGE_DIR/libexec

  # -- Libraries
  install $SOURCE_DIR/lib/libboost_filesystem.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libboost_program_options.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libboost_thread.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpython3.8.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libQt5Widgets.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libQt5Gui.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libQt5Core.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libGL.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libGLdispatch.so.0* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libGLX.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpng16.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libharfbuzz.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libexpat.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libutil.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libharfbuzz.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libicui18n.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libicuuc.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpcre2-16.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libdouble-conversion.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libglib-2.0.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libicudata.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpcre.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libbsd.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libfreetype.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libgraphite2.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libX11.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libxcb.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libXau.so.6* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libXdmcp.so.6* $PACKAGE_DIR/lib

  # -- Python 3.8
  # -- The whole python 3.8 should be copied in lib/python3.8
  mkdir -p $PACKAGE_DIR/lib/python3.8
  cp -r $SOURCE_DIR/lib/python3.8/* $PACKAGE_DIR/lib/python3.8

  #------------------------------------------
  #-- ECP5 tools
  #------------------------------------------
  # -- Executable
  install $SOURCE_DIR/bin/ecppack $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/ecppack $PACKAGE_DIR/libexec

  # -- Share
  mkdir -p $PACKAGE_DIR/share/trellis
  cp -r $SOURCE_DIR/share/trellis/* $PACKAGE_DIR/share/trellis 

  # -----------------------------------
  # -- NETXPNR-ECP5
  # -----------------------------------
  #install $TEMPLATE/nextpnr-ice40 $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/nextpnr-ecp5 $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/nextpnr-ecp5 $PACKAGE_DIR/libexec


fi

# --- Files to copy for the Linux ARM-64 platforms
if [ "$ARCH" == "linux_aarch64" ]; then

  echo "* Copying Linux files..."
  echo ""
  # --------------------
  # -- System tools
  # --------------------

  # -- Executables
  install $SOURCE_DIR/bin/lsusb $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/lsftdi $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/lsusb $PACKAGE_DIR/libexec
  install $SOURCE_DIR/libexec/lsftdi $PACKAGE_DIR/libexec

  # -- Libraries
  install $SOURCE_DIR/lib/ld-linux-aarch64.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libc.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libudev.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpthread.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/librt.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libusb-1.0.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libftdi1.so* $PACKAGE_DIR/lib

  # ---------------------------
  # -- Iceprog
  # ---------------------------
  # -- Executable
  install $SOURCE_DIR/bin/iceprog $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/iceprog $PACKAGE_DIR/libexec

fi


# --- Files to copy for the MAC platforms
if [ "$ARCH" == "darwin" ]; then

  echo "* Copying MAC files..."
  echo ""
  # --------------------
  # -- System tools
  # --------------------

  # -- Executables
  install $SOURCE_DIR/bin/lsusb $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/lsftdi $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/lsusb $PACKAGE_DIR/libexec
  install $SOURCE_DIR/libexec/lsftdi $PACKAGE_DIR/libexec
  install $SOURCE_DIR/libexec/realpath $PACKAGE_DIR/libexec

  # -- Copy the ftdi_eeprom file
  install $TOOL_SYSTEM_SRC/bin/ftdi_eeprom $PACKAGE_DIR/bin

  # -- Libraries
  install $SOURCE_DIR/lib/libusb-1.0.0.dylib $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libftdi1.2.5.0.dylib $PACKAGE_DIR/lib

  # ---------------------------
  # -- Iceprog
  # ---------------------------
  install $SOURCE_DIR/bin/iceprog $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/iceprog $PACKAGE_DIR/libexec

fi


# --- Files to copy for the WINDOWS platforms
if [ "$ARCH" == "windows_amd64" ]; then
  echo "* Copying Windows files..."
  echo ""

  # --------------------
  # -- System tools
  # --------------------

  # -- Executables and libraries
  # -- (The dlls are located along with the executables
  # --  instead of in the lib folder)
  install $SOURCE_DIR/bin/lsusb.exe $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/lsftdi.exe $PACKAGE_DIR/bin

  # -- Copy the ftdi_eeprom file
  install $TOOL_SYSTEM_SRC/bin/ftdi_eeprom.exe $PACKAGE_DIR/bin

  # -- Libraries
  install $SOURCE_DIR/lib/libusb-1.0.dll $PACKAGE_DIR/bin
  install $SOURCE_DIR/lib/libftdi1.dll $PACKAGE_DIR/bin

  # ---------------------------
  # -- Iceprog
  # ---------------------------
  install $SOURCE_DIR/bin/iceprog.exe $PACKAGE_DIR/bin

  # ----------------------------
  # -- YOSYS
  # ----------------------------
  # -- Executables
  install $SOURCE_DIR/bin/yosys.exe $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/yosys-abc.exe $PACKAGE_DIR/bin

  # -- Libraries
  install $SOURCE_DIR/lib/libstdc++*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libreadline*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libffi*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libdl.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/tcl*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libgcc_s*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/zlib1.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libwinpthread*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libtermcap*.dll $PACKAGE_DIR/lib

  # -- Share
  mkdir -p $PACKAGE_DIR/share/yosys
  cp -r $SOURCE_DIR/share/yosys/* $PACKAGE_DIR/share/yosys


  #------------------------------------------
  #-- ICE40 tools
  #------------------------------------------
  # -- Executable
  install $SOURCE_DIR/bin/icebram.exe $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/icemulti.exe $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/icepack.exe $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/icepll.exe $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/icetime.exe $PACKAGE_DIR/bin

 # -- Share
  mkdir -p $PACKAGE_DIR/share/icebox
  cp -r $SOURCE_DIR/share/icebox/* $PACKAGE_DIR/share/icebox


  # -----------------------------------
  # -- NETXPNR-ICE40
  # -----------------------------------
  # -- Executable
  install $SOURCE_DIR/bin/nextpnr-ice40.exe $PACKAGE_DIR/bin

  # -- Libraries
  install $SOURCE_DIR/lib/libboost_filesystem*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libboost_program_options*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libboost_thread*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpython*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/Qt5Widgets*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/Qt5Gui*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/Qt5Core*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpng16*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libharfbuzz*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libexpat*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/icuuc*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/iconv*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpcre2-*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libintl*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libglib-2.0* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/icudata*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpcre*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libfreetype*.dll $PACKAGE_DIR/lib

  # -- Python 3.8
  # -- The whole python 3.8 should be copied in lib/python3.8
  mkdir -p $PACKAGE_DIR/lib/python3.8
  cp -r $SOURCE_DIR/lib/python3.8/* $PACKAGE_DIR/lib/python3.8
  
fi


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

tar vzcf ../$PACKAGE_NAME ./* 
echo "--> Package created: $PACKAGE_NAME"





