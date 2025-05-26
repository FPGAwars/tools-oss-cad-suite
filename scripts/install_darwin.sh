# This file is sourced in rather than executed a a top level script.
# Destination directory $PACKAGE_DIR is assumed to be empty.

assert_dir_empty $PACKAGE_DIR

# -- Copy entire directory trees.
# -- Beware of 'cp -r' because it doesn't preserve symlinks.
rsync -a \
    $SOURCE_DIR/ $PACKAGE_DIR

# -- Create an alias, per https://github.com/FPGAwars/apio/issues/608
cp $PACKAGE_DIR/lib/libusb-1.0.0.dylib $PACKAGE_DIR/lib/libusb-1.0.dylib

# -- Sanity checks
assert_executable $PACKAGE_DIR/bin/yosys
assert_executable $PACKAGE_DIR/bin/nextpnr-ice40 
assert_executable $PACKAGE_DIR/bin/nextpnr-ecp5
assert_executable $PACKAGE_DIR/bin/nextpnr-himbaechel
assert_executable $PACKAGE_DIR/bin/dot
assert_executable $PACKAGE_DIR/bin/gtkwave

assert_is_file $PACKAGE_DIR/lib/libusb-1.0.0.dylib
assert_is_file $PACKAGE_DIR/lib/libusb-1.0.dylib



