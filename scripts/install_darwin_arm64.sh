# This file is sourced in rather than executed a a top level script.
# Destination directory $PACKAGE_DIR is assumed to be empty.

# -- Copy entire directory trees.
cp -rp $SOURCE_DIR/bin $PACKAGE_DIR
cp -rp $SOURCE_DIR/lib $PACKAGE_DIR
cp -rp $SOURCE_DIR/libexec $PACKAGE_DIR
cp -rp $SOURCE_DIR/share $PACKAGE_DIR
cp -rp $SOURCE_DIR/Frameworks $PACKAGE_DIR
cp -rp $SOURCE_DIR/license $PACKAGE_DIR

# -- Copy individual files.
install $SOURCE_DIR/activate $PACKAGE_DIR
install $SOURCE_DIR/environment $PACKAGE_DIR
install $SOURCE_DIR/README $PACKAGE_DIR
