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

#------------------------------------------------------------------------------ 

  # ----------------------------
  # -- YOSYS
  # ----------------------------
  # -- Executables
  install $SOURCE_DIR/bin/yosys $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/yosys $PACKAGE_DIR/libexec
  install $SOURCE_DIR/bin/yosys-abc $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/yosys-abc $PACKAGE_DIR/libexec

  # -- Libraries
  install $SOURCE_DIR/lib/libstdc++.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libm.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libreadline.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libffi.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libdl.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libz.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libtcl* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libgcc_s.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libtinfo.so* $PACKAGE_DIR/lib
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
  install $SOURCE_DIR/lib/libboost_filesystem.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libboost_program_options.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libboost_thread.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpython3.8.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libQt5Widgets.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libQt5Gui.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libQt5Core.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libGL.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libGLdispatch.so.0* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libGLX.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpng16.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libharfbuzz.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libexpat.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libutil.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libharfbuzz.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libicui18n.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libicuuc.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpcre2-16.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libdouble-conversion.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libglib-2.0.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libicudata.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libpcre.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libbsd.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libfreetype.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libgraphite2.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libX11.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libxcb.so* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libXau.so.6* $PACKAGE_DIR/lib
  install $SOURCE_DIR/lib/libXdmcp.so.6* $PACKAGE_DIR/lib

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
  #install $TEMPLATE/nextpnr-ice40 $PACKAGE_DIR/bin
  install $SOURCE_DIR/bin/nextpnr-ecp5 $PACKAGE_DIR/bin
  install $SOURCE_DIR/libexec/nextpnr-ecp5 $PACKAGE_DIR/libexec

#-------------------------------------------------------------
#-- PROGRAMMERS!!
#-------------------------------------------------------------

# ----------------------
# -- OPENFPGA LOADER
# ----------------------
install $SOURCE_DIR/bin/openFPGALoader $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/openFPGALoader $PACKAGE_DIR/libexec

install $SOURCE_DIR/lib/libhidapi-libusb.so* $PACKAGE_DIR/lib

# ------------------------
# -- DFU
# ------------------------
install $SOURCE_DIR/bin/dfu-util $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/dfu-util $PACKAGE_DIR/libexec
            

# --------------------------
# -- FUJPROG
# --------------------------
install $SOURCE_DIR/bin/fujprog $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/fujprog $PACKAGE_DIR/libexec

# --------------------------
# -- ICEPROGDUINO
# --------------------------
install $SOURCE_DIR/bin/iceprogduino $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/iceprogduino $PACKAGE_DIR/libexec

# --------------------------
# -- ICESPROG
# --------------------------
install $SOURCE_DIR/bin/icesprog $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/icesprog $PACKAGE_DIR/libexec

install $SOURCE_DIR/lib/libhidapi-hidraw.so* $PACKAGE_DIR/lib
# ---------------------------------------------------------
# -- SIMULATION!!
# ---------------------------------------------------------

# --------------------
# -- IVERILOG
# --------------------
install $SOURCE_DIR/bin/iverilog $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/iverilog $PACKAGE_DIR/libexec
install $SOURCE_DIR/bin/vvp $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/vvp $PACKAGE_DIR/libexec
install $SOURCE_DIR/bin/iverilog-vpi $PACKAGE_DIR/bin

install $SOURCE_DIR/libexec/ivl $PACKAGE_DIR/libexec
install $SOURCE_DIR/libexec/ivlpp $PACKAGE_DIR/libexec

# -- Libraries
mkdir -p $PACKAGE_DIR/lib/ivl
cp -r $SOURCE_DIR/lib/ivl/* $PACKAGE_DIR/lib/ivl 
install $SOURCE_DIR/lib/libbz2* $PACKAGE_DIR/lib


# --------------------------------------
# -- TODO: verilator
# --------------------------------------
install $SOURCE_DIR/bin/verilator $PACKAGE_DIR/bin 
install $SOURCE_DIR/libexec/verilator_bin $PACKAGE_DIR/bin
