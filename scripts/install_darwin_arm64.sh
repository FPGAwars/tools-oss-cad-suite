
# --------------------
# -- System tools
# --------------------

# -- Executables
install $SOURCE_DIR/bin/lsusb $PACKAGE_DIR/bin
install $SOURCE_DIR/bin/lsftdi $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/lsusb $PACKAGE_DIR/libexec
install $SOURCE_DIR/libexec/lsftdi $PACKAGE_DIR/libexec
install $SOURCE_DIR/libexec/realpath $PACKAGE_DIR/libexec


# -- Libraries
install $SOURCE_DIR/lib/lib* $PACKAGE_DIR/lib

# ---------------------------
# -- Iceprog
# ---------------------------
install $SOURCE_DIR/bin/iceprog $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/iceprog $PACKAGE_DIR/libexec

# ----------------------------
# -- YOSYS
# ----------------------------
# -- Executables
install $SOURCE_DIR/bin/yosys $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/yosys $PACKAGE_DIR/libexec
install $SOURCE_DIR/bin/yosys-abc $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/yosys-abc $PACKAGE_DIR/libexec

# -- Libraries
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


# -- Python 3.11
# -- The whole python 3.8 should be copied in lib/python3.8
mkdir -p $PACKAGE_DIR/lib/python3.11
cp -r $SOURCE_DIR/lib/python3.11/* $PACKAGE_DIR/lib/python3.11

# -- Graphical frameworks
mkdir -p $PACKAGE_DIR/Frameworks/QtOpenGL.framework
cp -r $SOURCE_DIR/Frameworks/QtOpenGL.framework/* $PACKAGE_DIR/Frameworks/QtOpenGL.framework

mkdir -p $PACKAGE_DIR/Frameworks/QtWidgets.framework
cp -r $SOURCE_DIR/Frameworks/QtWidgets.framework/* $PACKAGE_DIR/Frameworks/QtWidgets.framework

mkdir -p $PACKAGE_DIR/Frameworks/QtGui.framework
cp -r $SOURCE_DIR/Frameworks/QtGui.framework/* $PACKAGE_DIR/Frameworks/QtGui.framework

mkdir -p $PACKAGE_DIR/Frameworks/QtCore.framework
cp -r $SOURCE_DIR/Frameworks/QtCore.framework/* $PACKAGE_DIR/Frameworks/QtCore.framework




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
install $SOURCE_DIR/bin/nextpnr-ecp5 $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/nextpnr-ecp5 $PACKAGE_DIR/libexec



#------------------------------------------
#-- Gowin tools
#------------------------------------------
# -----------------------------------
# -- NETXPNR-Gowin
# -----------------------------------
install $SOURCE_DIR/bin/nextpnr-gowin $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/nextpnr-gowin $PACKAGE_DIR/libexec

#-------------------------------------------------------------
#-- PROGRAMMERS!!
#-------------------------------------------------------------

# ----------------------
# -- OPENFPGA LOADER
# ----------------------
install $SOURCE_DIR/bin/openFPGALoader $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/openFPGALoader $PACKAGE_DIR/libexec


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
# -- ICESPROG
# --------------------------
install $SOURCE_DIR/bin/icesprog $PACKAGE_DIR/bin
install $SOURCE_DIR/libexec/icesprog $PACKAGE_DIR/libexec

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

# --------------------------------------
# -- Verilator
# --------------------------------------
install $SOURCE_DIR/bin/verilator $PACKAGE_DIR/bin
install $SOURCE_DIR/bin/verilator_bin $PACKAGE_DIR/bin 
install $SOURCE_DIR/libexec/verilator_bin $PACKAGE_DIR/libexec/
mkdir -p $PACKAGE_DIR/share/verilator/include
install $SOURCE_DIR/share/verilator/include/verilated_std.sv $PACKAGE_DIR/share/verilator/include

