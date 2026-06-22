## Board constraints for MCU_4cores_muticycle board_top.
## Top-level ports:
##   clk_in1 : 50 MHz board oscillator
##   rst_btn : reset switch, active high in RTL

set_property PACKAGE_PIN G22 [get_ports clk_in1]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in1]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk_in1]

set_property PACKAGE_PIN AC3 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS18 [get_ports rst_btn]

## Debug hub clock for ILA.
## Apply these after debug core insertion if Vivado warns dbg_hub is missing.
set_property C_CLK_INPUT_FREQ_HZ 50000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets sys_clk]
