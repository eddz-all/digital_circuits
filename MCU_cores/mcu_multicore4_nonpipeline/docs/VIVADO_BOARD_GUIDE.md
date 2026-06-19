# Vivado board guide for multicore4 non-pipeline

This guide is only for packaging the existing 4-core non-pipelined design for
the board. It does not require changing the 4-core RTL.

## 1. Project

Create a new RTL project with:

```text
Top module: board_top
Language: VHDL
VHDL standard: VHDL 2008
Target part: xc7k160tffg676-2
```

## 2. Add RTL sources

Add these design sources in this order:

```text
rtl/mcu_v1_butterfly_core.vhd
rtl/mcu_fft_system_multicore4.vhd
MCU_cores/mcu_multicore4_nonpipeline/rtl/board_top.vhd
```

Do not add testbench files as design sources.

Add this constraints file:

```text
MCU_cores/mcu_multicore4_nonpipeline/constrs/board_top.xdc
```

## 3. Required IP names

The wrapper expects these exact component names:

```text
clk_wiz_0
test_ROM
verify_RAM
ila_0
```

### clk_wiz_0

```text
IP: Clocking Wizard
Input clock: 50 MHz
Output clock clk_out1: 50 MHz
locked port: enabled
reset port: enabled, active high
```

The wrapper ties the clock wizard reset input to `0` and uses
`rst_btn or not locked` as the system reset.

### test_ROM

```text
IP: Block Memory Generator
Memory type: Single Port RAM
Write width: 16
Read width: 16
Write depth: 256
Address width: 8
Enable port ena: enabled
Write enable width: 1
Output register: disabled
Initialization file: FFT_input.coe
```

The design reads only the teacher signal window `test_ROM[128..143]`.

### verify_RAM

```text
IP: Block Memory Generator
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

```text
Number of probes: 8
Sample depth: 1024 or 2048

probe0: 16
probe1: 20
probe2: 6
probe3: 16
probe4: 1
probe5: 1
probe6: 1
probe7: 1
```

Probe mapping:

```text
probe0 = test_vector_in
probe1 = cnt_test
probe2 = verify_ila_addr
probe3 = verify_readback_data
probe4 = verify_readback_valid
probe5 = verify_ram_we
probe6 = done
probe7 = illegal
```

Use `probe4 == 1` to capture the final `verify_RAM[0..15]` readback stream.

## 4. Board behavior

After reset is released, `board_top`:

```text
1. Reads FFT_input.coe signal slots 128..143 through test_ROM.
2. Runs the existing 4-core non-pipelined FFT system.
3. Writes verify_RAM[0..15] as real0..real7, then imag0..imag7.
4. Reads verify_RAM[0..15] back for ILA observation.
```

The readback phase is only for observation. It is not included in `cnt_test`.

## 5. Expected counter meaning

`cnt_test` follows the current 4-core system counter:

```text
count starts when stage 0 dispatch begins after input loading and packing
count stops when the final output slot is written
```

The current GHDL result for the underlying 4-core system is:

```text
cnt_cycles = 33
```

This follows the same counter boundary style as the CORES 8-core board branch:
the external input loading phase still exists, but it is not included in
`cnt_test`.
