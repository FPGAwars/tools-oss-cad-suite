
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

# ----------------------------
# -- YOSYS
# ----------------------------
# -- Executables
install $SOURCE_DIR/bin/yosys $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/yosys $PACKAGE_DIR/libexec
install $SOURCE_DIR/bin/yosys-abc $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/yosys-abc $PACKAGE_DIR/libexec

# -- Libraries
install $SOURCE_DIR/lib/libreadline* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libffi* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libz* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libtcl* $PACKAGE_DIR/lib
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
install $SOURCE_DIR/lib/libboost_filesystem* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libboost_program_options* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libboost_thread* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libpython3.8* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libpng16* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libharfbuzz* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libexpat* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libharfbuzz* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libicui18n* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libicuuc* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libpcre* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libglib-2.0* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libicudata* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libfreetype* $PACKAGE_DIR/lib
install $SOURCE_DIR/lib/libgraphite2* $PACKAGE_DIR/lib

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
install $SOURCE_DIR/bin/nextpnr-ecp5 $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/nextpnr-ecp5 $PACKAGE_DIR/libexec





