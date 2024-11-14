# This file is sourced in rather than executed a a top level script.
# Destination directory $PACKAGE_DIR is assumed to be empty.

assert_dir_empty $PACKAGE_DIR

# -- Copy entire directory trees.
# -- Beware of 'cp -r' because it doesn't preserve symlinks.
rsync -a \
    $SOURCE_DIR/ $PACKAGE_DIR

# -- Sanity checks
assert_executable $PACKAGE_DIR/bin/yosys.exe
assert_executable $PACKAGE_DIR/bin/nextpnr-ice40.exe 
assert_executable $PACKAGE_DIR/bin/nextpnr-ecp5.exe
assert_executable $PACKAGE_DIR/bin/nextpnr-himbaechel.exe
assert_executable $PACKAGE_DIR/bin/gtkwave.exe

