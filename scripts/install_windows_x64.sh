# This file is sourced in rather than executed a a top level script.
# Destination directory $PACKAGE_DIR is assumed to be empty.

assert_dir_empty $PACKAGE_DIR

# -- Copy entire directory trees.
cp -rp $SOURCE_DIR/bin $PACKAGE_DIR
cp -rp $SOURCE_DIR/lib $PACKAGE_DIR
cp -rp $SOURCE_DIR/share $PACKAGE_DIR
cp -rp $SOURCE_DIR/license $PACKAGE_DIR

# -- Copy individual files.
install $SOURCE_DIR/README $PACKAGE_DIR
install $SOURCE_DIR/*.bat $PACKAGE_DIR

# -- Copy the ftdi_eeprom file from the TOOL_SYSTEM package.
install $TOOL_SYSTEM_SRC/bin/ftdi_eeprom.exe $PACKAGE_DIR/bin

# -- Sanity checks
assert_executable $PACKAGE_DIR/bin/yosys.exe
assert_executable $PACKAGE_DIR/bin/nextpnr-ice40.exe 
assert_executable $PACKAGE_DIR/bin/nextpnr-ecp5.exe
assert_executable $PACKAGE_DIR/bin/nextpnr-himbaechel.exe
assert_executable $PACKAGE_DIR/bin/ftdi_eeprom.exe

