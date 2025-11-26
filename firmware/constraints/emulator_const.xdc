# Constraints file for the emulator
# Author: Prerna Baranwal 
# KTH Emulator
# Spartan-7 XC7S15CPGA196-2

# FLASH SPIx4 MX25V8035FM1I
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

# Reset from lpGBT GPIO
set_property PACKAGE_PIN K1 [get_ports LPGBT_HARD_RSTB]
set_property IOSTANDARD LVCMOS12 [get_ports LPGBT_HARD_RSTB]
set_property PULLUP true [get_ports LPGBT_HARD_RSTB]

# CLK 40MHz from lpGBT ECLK
set_property PACKAGE_PIN G2 [get_ports LPGBT_CLK40M_P]
set_property PACKAGE_PIN G1 [get_ports LPGBT_CLK40M_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports LPGBT_CLK40M_P]
#create_clock -period 25.000 -name LPGBT_CLK [get_ports LPGBT_CLK40M_P]

# ELINKs
set_property IOSTANDARD DIFF_HSUL_12 [get_ports FAST_CMD_P]
set_property PACKAGE_PIN M2 [get_ports FAST_CMD_P]
set_property PACKAGE_PIN M1 [get_ports FAST_CMD_N]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports FAST_CMD_N]


#lpGBT regular: link 1 luminosity, link 0 timing
set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_P[0]}]
set_property PACKAGE_PIN C2 [get_ports {TIMING_DOUT_P[0]}]
set_property PACKAGE_PIN C1 [get_ports {TIMING_DOUT_N[0]}]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_N[0]}]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_P[1]}]
set_property PACKAGE_PIN P3 [get_ports {TIMING_DOUT_P[1]}]
set_property PACKAGE_PIN P2 [get_ports {TIMING_DOUT_N[1]}]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_N[1]}]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_P[0]}]
set_property PACKAGE_PIN J1 [get_ports {LUMI_DOUT_P[0]}]
set_property PACKAGE_PIN H1 [get_ports {LUMI_DOUT_N[0]}]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_N[0]}]

set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_P[1]}]
set_property PACKAGE_PIN N4 [get_ports {LUMI_DOUT_P[1]}]
set_property PACKAGE_PIN M4 [get_ports {LUMI_DOUT_N[1]}]
set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_N[1]}]


#lpGBT swapped pins: link 0 luminosity, link 1 timing
# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_P[0]}]
# set_property PACKAGE_PIN J1 [get_ports {TIMING_DOUT_P[0]}]
# set_property PACKAGE_PIN H1 [get_ports {TIMING_DOUT_N[0]}]
# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_N[0]}]

# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_P[1]}]
# set_property PACKAGE_PIN N4 [get_ports {TIMING_DOUT_P[1]}]
# set_property PACKAGE_PIN M4 [get_ports {TIMING_DOUT_N[1]}]
# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {TIMING_DOUT_N[1]}]

# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_P[0]}]
# set_property PACKAGE_PIN C2 [get_ports {LUMI_DOUT_P[0]}]
# set_property PACKAGE_PIN C1 [get_ports {LUMI_DOUT_N[0]}]
# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_N[0]}]

# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_P[1]}]
# set_property PACKAGE_PIN P3 [get_ports {LUMI_DOUT_P[1]}]
# set_property PACKAGE_PIN P2 [get_ports {LUMI_DOUT_N[1]}]
# set_property IOSTANDARD DIFF_HSUL_12 [get_ports {LUMI_DOUT_N[1]}]

##!set_property PACKAGE_PIN L4 [get_ports I2C_ADDR[1]]
##!set_property IOSTANDARD LVCMOS12 [get_ports I2C_ADDR[1]]
##!set_property PACKAGE_PIN L3 [get_ports I2C_ADDR[2]]
##!set_property IOSTANDARD LVCMOS12 [get_ports I2C_ADDR[2]]
##!set_property PACKAGE_PIN L2 [get_ports I2C_ADDR[3]]
##!set_property IOSTANDARD LVCMOS12 [get_ports I2C_ADDR[3]]

##!set_property PACKAGE_PIN P4 [get_ports I2C_SCL]
##!set_property IOSTANDARD LVCMOS12 [get_ports I2C_SCL]
##!set_property PACKAGE_PIN N3 [get_ports I2C_SDA]
##!set_property IOSTANDARD LVCMOS12 [get_ports I2C_SDA]

#################################################################
# Local CLK 200MHz
set_property PACKAGE_PIN G14 [get_ports REFCLK_P]
# set_property PACKAGE_PIN F14 [get_ports REFCLK_N]
set_property IOSTANDARD LVDS_25 [get_ports REFCLK_P]
#create_clock -period 5.000 -name clk200 [get_ports REFCLK_P]

##!set_property PACKAGE_PIN H14 [get_ports DIPSW[0]]
##!set_property IOSTANDARD LVCMOS25 [get_ports DIPSW[0]]
##!set_property PULLUP true [get_ports DIPSW[0]]
##!set_property PACKAGE_PIN J14 [get_ports DIPSW[1]]
##!set_property IOSTANDARD LVCMOS25 [get_ports DIPSW[1]]
##!set_property PULLUP true [get_ports DIPSW[1]]
##!set_property PACKAGE_PIN L14 [get_ports DIPSW[2]]
##!set_property IOSTANDARD LVCMOS25 [get_ports DIPSW[2]]
##!set_property PULLUP true [get_ports DIPSW[2]]

##!set_property PACKAGE_PIN B6 [get_ports TESTPIN[0]]
##!set_property IOSTANDARD LVCMOS25 [get_ports TESTPIN[0]]
##!set_property PACKAGE_PIN A5 [get_ports TESTPIN[1]]
##!set_property IOSTANDARD LVCMOS25 [get_ports TESTPIN[1]]
##!
##!set_property PACKAGE_PIN A2 [get_ports TP[1]]
##!set_property IOSTANDARD LVCMOS12 [get_ports TP[1]]
##!set_property PACKAGE_PIN A3 [get_ports TP[2]]
##!set_property IOSTANDARD LVCMOS12 [get_ports TP[2]]

set_property SLEW FAST [get_ports {LUMI_DOUT_N[1]}]
set_property SLEW FAST [get_ports {LUMI_DOUT_P[1]}]
set_property SLEW FAST [get_ports {LUMI_DOUT_N[0]}]
set_property SLEW FAST [get_ports {LUMI_DOUT_P[0]}]
set_property SLEW FAST [get_ports {TIMING_DOUT_N[1]}]
set_property SLEW FAST [get_ports {TIMING_DOUT_P[1]}]
set_property SLEW FAST [get_ports {TIMING_DOUT_N[0]}]
set_property SLEW FAST [get_ports {TIMING_DOUT_P[0]}]


##! set input and output delay

#set_output_delay 0.0 -clock clk320_clk_wiz_0   [get_ports {LUMI_DOUT_N[0]}]
#set_output_delay 0.0 -clock clk320_clk_wiz_0  0 [get_ports {LUMI_DOUT_P[1]}]
#set_output_delay 0.0 -clock clk160_clk_wiz_0  0 [get_ports {TIMING_DOUT_N[1]}]
#set_output_delay 0.0 -clock clk160_clk_wiz_0  0 [get_ports {TIMING_DOUT_P[0]}]

#set_property MARK_DEBUG true [get_nets fastcmd_dec0/CE]
#
#
#set_property MARK_DEBUG true [get_nets fastcmd_dec0/AdditionalDelay]
#set_property MARK_DEBUG true [get_nets fastcmd_dec0/notQ2_p1]
#create_debug_core u_ila_0 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 2 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list clk0/inst/clk160]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#set_property port_width 8 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list {fastcmd_dec0/shiftreg[0]} {fastcmd_dec0/shiftreg[1]} {fastcmd_dec0/shiftreg[2]} {fastcmd_dec0/shiftreg[3]} {fastcmd_dec0/shiftreg[4]} {fastcmd_dec0/shiftreg[5]} {fastcmd_dec0/shiftreg[6]} {fastcmd_dec0/shiftreg[7]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
#set_property port_width 5 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list {fastcmd_dec0/CNTVALUE[0]} {fastcmd_dec0/CNTVALUE[1]} {fastcmd_dec0/CNTVALUE[2]} {fastcmd_dec0/CNTVALUE[3]} {fastcmd_dec0/CNTVALUE[4]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
#set_property port_width 4 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list {fastcmd_dec0/dvalid_shift[0]} {fastcmd_dec0/dvalid_shift[1]} {fastcmd_dec0/dvalid_shift[2]} {fastcmd_dec0/dvalid_shift[3]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
#set_property port_width 1 [get_debug_ports u_ila_0/probe3]
#connect_debug_port u_ila_0/probe3 [get_nets [list fastcmd_dec0/AdditionalDelay]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
#set_property port_width 1 [get_debug_ports u_ila_0/probe4]
#connect_debug_port u_ila_0/probe4 [get_nets [list fastcmd_dec0/CE]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
#set_property port_width 1 [get_debug_ports u_ila_0/probe5]
#connect_debug_port u_ila_0/probe5 [get_nets [list fastcmd_dec0/notQ1]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]


set_property MARK_DEBUG true [get_nets {dout_lumi[0]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[1]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[2]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[3]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[4]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[5]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[6]}]
set_property MARK_DEBUG true [get_nets {dout_lumi[7]}]


create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk0/inst/clk160]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 5 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {fastcmd_dec0/CNTVALUE[0]} {fastcmd_dec0/CNTVALUE[1]} {fastcmd_dec0/CNTVALUE[2]} {fastcmd_dec0/CNTVALUE[3]} {fastcmd_dec0/CNTVALUE[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 8 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {fastcmd_dec0/shiftreg[0]} {fastcmd_dec0/shiftreg[1]} {fastcmd_dec0/shiftreg[2]} {fastcmd_dec0/shiftreg[3]} {fastcmd_dec0/shiftreg[4]} {fastcmd_dec0/shiftreg[5]} {fastcmd_dec0/shiftreg[6]} {fastcmd_dec0/shiftreg[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 4 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {fastcmd_dec0/dvalid_shift[0]} {fastcmd_dec0/dvalid_shift[1]} {fastcmd_dec0/dvalid_shift[2]} {fastcmd_dec0/dvalid_shift[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list fastcmd_dec0/notQ1]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list fastcmd_dec0/notQ2]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list fastcmd_dec0/Q1]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list fastcmd_dec0/Q2]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list clk0/inst/clk80]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 8 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {dout_lumi[0]} {dout_lumi[1]} {dout_lumi[2]} {dout_lumi[3]} {dout_lumi[4]} {dout_lumi[5]} {dout_lumi[6]} {dout_lumi[7]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets serialclk_timing]
