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
  install $SOURCE_DIR/lib/lib* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/tcl*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/zlib1.dll $PACKAGE_DIR/lib

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
  install $SOURCE_DIR/lib/Qt5Widgets*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/Qt5Gui*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/Qt5Core*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/icuuc*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/iconv*.dll $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/icudata*.dll $PACKAGE_DIR/lib


  # -- Python 3.11
  # -- The whole python 3.8 should be copied in lib/python3.11
  mkdir -p $PACKAGE_DIR/lib/python3.11
  cp -r $SOURCE_DIR/lib/python3.11/* $PACKAGE_DIR/lib/python3.11
  
#------------------------------------------
#-- ECP5 tools
#------------------------------------------
# -- Executable
install $SOURCE_DIR/bin/ecppack.exe $PACKAGE_DIR/bin

# -- Share
mkdir -p $PACKAGE_DIR/share/trellis
cp -r $SOURCE_DIR/share/trellis/* $PACKAGE_DIR/share/trellis 

# -----------------------------------
# -- NETXPNR-ECP5
# -----------------------------------
install $SOURCE_DIR/bin/nextpnr-ecp5.exe $PACKAGE_DIR/bin


#------------------------------------------
#-- Gowin tools
#------------------------------------------
# -----------------------------------
# -- NETXPNR-Gowin
# -----------------------------------
install $SOURCE_DIR/bin/nextpnr-himbaechel.exe $PACKAGE_DIR/bin

# ---------------------------------------------------------
# -- SIMULATION!!
# ---------------------------------------------------------

# ----------------------
# -- OPENFPGA LOADER
# ----------------------
install $SOURCE_DIR/bin/openFPGALoader.exe $PACKAGE_DIR/bin

install $SOURCE_DIR/lib/libhidapi*.dll $PACKAGE_DIR/lib

# ------------------------
# -- DFU
# ------------------------
install $SOURCE_DIR/bin/dfu-util.exe $PACKAGE_DIR/bin
            

# --------------------------
# -- FUJPROG
# --------------------------
install $SOURCE_DIR/bin/fujprog.exe $PACKAGE_DIR/bin

# --------------------------
# -- ICEPROGDUINO
# --------------------------
install $SOURCE_DIR/bin/iceprogduino.exe $PACKAGE_DIR/bin

# --------------------------
# -- ICESPROG
# --------------------------
install $SOURCE_DIR/bin/icesprog.exe $PACKAGE_DIR/bin

# --------------------
# -- IVERILOG
# --------------------
install $SOURCE_DIR/bin/iverilog.exe $PACKAGE_DIR/bin
install $SOURCE_DIR/bin/vvp.exe $PACKAGE_DIR/bin
install $SOURCE_DIR/bin/iverilog-vpi.exe $PACKAGE_DIR/bin

# -- Libraries
mkdir -p $PACKAGE_DIR/lib/ivl
cp -r $SOURCE_DIR/lib/ivl/* $PACKAGE_DIR/lib/ivl



# --------------------------------------
# -- Verilator
# --------------------------------------
install $SOURCE_DIR/bin/verilator $PACKAGE_DIR/bin 
install $SOURCE_DIR/bin/verilator_bin.exe $PACKAGE_DIR/bin
mkdir -p $PACKAGE_DIR/share/verilator/include
install $SOURCE_DIR/share/verilator/include/verilated_std.sv $PACKAGE_DIR/share/verilator/include

