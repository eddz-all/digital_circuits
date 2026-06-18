# Vivado Board Guide

This guide is for the latest `MCU_cores/mcu_8core_dsp` version.

## 1. Project

Create a new RTL project in Vivado.

Recommended project settings:

```text
Top module: board_top
Target part: xc7k160tffg676-2
Language: VHDL
```

Set every VHDL source file to `VHDL 2008`.

## 2. Add RTL Sources

Add these files in this order:

```text
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_8core_dsp_pkg.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_8core_instr_rom.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_8core_decoder.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_8core_regfile.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_8core_dsp_worker.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_v1_core.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/mcu_fft_system.vhd
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/rtl/board_top.vhd
```

Do not add the testbench files as design sources.

## 3. Add Constraints

Use:

```text
/home/huancheng/MCU/MCU_DEV/board_top.xdc
```

The important constraints are:

```tcl
set_property PACKAGE_PIN G22 [get_ports clk_in1]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in1]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports clk_in1]

set_property PACKAGE_PIN AC3 [get_ports rst_btn]
set_property IOSTANDARD LVCMOS18 [get_ports rst_btn]
```

`rst_btn` is active high in RTL.

## 4. Generate IP

Create these IPs with exactly these component names.

### clk_wiz_0

IP: Clocking Wizard

```text
Component name: clk_wiz_0
Input clock: 50 MHz
Output clock clk_out1: 50 MHz
locked port: enabled
reset port: enabled, active high
```

The design ties `reset` to `0`, and uses `locked` to generate system reset.

### test_ROM

IP: Block Memory Generator

Use Single Port RAM, not pure ROM, because `board_top` has `wea` and `dina`
ports.

```text
Component name: test_ROM
Interface type: Native
Memory type: Single Port RAM
Write width: 16
Read width: 16
Write depth: 256
Address width: 8
Enable port ena: enabled
Write enable width: 1
Output register: disabled
Initialization file: /home/huancheng/MCU/MCU_v1/FFT_input.coe
```

This version reads only `test_ROM[128..143]`.

### verify_RAM

IP: Block Memory Generator

```text
Component name: verify_RAM
Interface type: Native
Memory type: Single Port RAM
Write width: 16
Read width: 16
Write depth: 64
Address width: 6
Enable port ena: enabled
Write enable width: 1
Output register: disabled
Initialization file: none
```

### ila_0

IP: ILA

```text
Component name: ila_0
Number of probes: 6
Sample depth: 1024 or 2048
```

Probe widths:

```text
probe0: 16
probe1: 20
probe2: 6
probe3: 16
probe4: 1
probe5: 1
```

Probe mapping:

```text
probe0 = test_vector_in
probe1 = cnt_test
probe2 = verify_readback_addr_q
probe3 = verify_readback_data
probe4 = verify_readback_valid
probe5 = verify_ram_we
```

Recommended ILA trigger:

```text
probe4 == 1
```

This captures the final readback from `verify_RAM`.

## 5. Behavioral Simulation

Before running board synthesis, run the pure RTL system testbench.

Add this as a simulation source:

```text
/home/huancheng/MCU/MCU_cores/mcu_8core_dsp/tb/mcu_fft_system_tb.vhd
```

Set simulation top to:

```text
mcu_fft_system_tb
```

Expected final message:

```text
mcu_fft_system_tb passed, counted_cycles=60
```

Do not use `board_top` as the first simulation top because it depends on
Vivado IP.

## 6. Synthesis And Bitstream

After all RTL files and IPs are ready:

```text
1. Run Synthesis
2. Run Implementation
3. Generate Bitstream
4. Open Hardware Manager
5. Open Target
6. Program Device
```

If Vivado reports missing modules, check that the four IP names are exactly:

```text
clk_wiz_0
test_ROM
verify_RAM
ila_0
```

## 7. Board Run

After programming the FPGA:

```text
1. Assert rst_btn high
2. Release rst_btn low
3. Arm the ILA trigger
```

The design will:

```text
1. Load 16 input words from test_ROM[128..143]
2. Start cnt_test when core execution begins
3. Run eight single-cycle DSP workers
4. Write 16 output words to verify_RAM
5. Read back verify_RAM[0..15] for ILA observation
```

Expected `cnt_test` final value:

```text
60 decimal = 0x0003C
```

Expected readback data:

```text
addr  0: F280
addr  1: E80A
addr  2: 1A80
addr  3: FEA2
addr  4: E080
addr  5: 16F6
addr  6: E680
addr  7: FA5E
addr  8: E900
addr  9: 317C
addr 10: 2C00
addr 11: 1F8C
addr 12: 0B00
addr 13: 0C84
addr 14: 1600
addr 15: D874
```

Expected input window:

```text
test_ROM[128]: FFF3
test_ROM[129]: FFE3
test_ROM[130]: FFE3
test_ROM[131]: 0000
test_ROM[132]: FFF7
test_ROM[133]: 001B
test_ROM[134]: 0006
test_ROM[135]: 0014
test_ROM[136]: 001B
test_ROM[137]: FFF7
test_ROM[138]: FFEE
test_ROM[139]: FFE9
test_ROM[140]: 0000
test_ROM[141]: 0012
test_ROM[142]: FFEB
test_ROM[143]: FFEC
```

