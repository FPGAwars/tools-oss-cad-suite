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
