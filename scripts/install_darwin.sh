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

  