# This file is sourced in rather than executed a a top level script.
# Destination directory $PACKAGE_DIR is assumed to be empty.

assert_dir_empty $PACKAGE_DIR

# -- Copy entire directory trees.
# -- Beware of 'cp -r' because it doesn't preserve symlinks.
rsync -a \
    $SOURCE_DIR/ $PACKAGE_DIR

# -- TODO: Consume this tool from a seperate apio package, to keep the 
# -- oss-cad-tools package as original as possible.
# --
# -- Copy the ftdi_eeprom file from the tools package.
install $TOOL_SYSTEM_SRC/bin/ftdi_eeprom $PACKAGE_DIR/bin

# -- Sanity checks
assert_executable $PACKAGE_DIR/bin/yosys
assert_executable $PACKAGE_DIR/bin/nextpnr-ice40 
assert_executable $PACKAGE_DIR/bin/nextpnr-ecp5
assert_executable $PACKAGE_DIR/bin/nextpnr-himbaechel
assert_executable $PACKAGE_DIR/bin/dot
assert_executable $PACKAGE_DIR/bin/gtkwave
assert_executable $PACKAGE_DIR/bin/ftdi_eeprom
