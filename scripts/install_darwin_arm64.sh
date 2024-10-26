# This file is sourced in rather than executed a a top level script.
# Destination directory $PACKAGE_DIR is assumed to be empty.

# -- Copy key directories.
cp -rp $SOURCE_DIR/bin $PACKAGE_DIR
cp -rp $SOURCE_DIR/lib $PACKAGE_DIR
cp -rp $SOURCE_DIR/libexec $PACKAGE_DIR
cp -rp $SOURCE_DIR/share $PACKAGE_DIR

# -- Replace bin/nextpnr-ice40 with our simplified template.
install $TEMPLATE/nextpnr-ice40 $PACKAGE_DIR/bin
