# Vivado Board Guide

Use this guide for a new Vivado project based on:

```text
/home/huancheng/MCU/MCU_4cores_muticycle
```

## Add RTL Sources

Add these files as design sources in this order:

```text
rtl/mcu4_multi_pkg.vhd
rtl/mcu4_worker_instr_rom.vhd
rtl/mcu4_worker_decoder.vhd
rtl/mcu4_worker_core.vhd
rtl/mcu4_multicycle_core.vhd
rtl/mcu_fft_system.vhd
rtl/board_top.vhd
```

Set `board_top` as the top module.

Add this constraints file:

```text
constrs/board_top.xdc
```

If Vivado reports a duplicate clock constraint between `board_top.xdc` and `clk_wiz_0.xdc`, keep only one `create_clock` on `clk_in1`. This is a constraint cleanup issue, not an RTL issue.

## Generate IP

### `clk_wiz_0`

- IP: Clocking Wizard
- Component name: `clk_wiz_0`
- Input clock: 50 MHz
- Output clock: try 200 MHz for the performance run; if implementation WNS is
  negative, fall back to 180 MHz or 166.667 MHz
- Enable `locked`
- Reset port exists in the wrapper; RTL ties it to `0`

### `test_ROM`

- IP: Block Memory Generator
- Component name: `test_ROM`
- Memory type: Single Port RAM
- Width: 16
- Depth: 256
- Address width: 8
- Enable port: enabled
- Write enable width: 1
- Output register: disabled
- Initialize with the FFT input COE file used in the earlier project

The RTL reads only addresses `128..143`.

### `verify_RAM`

- IP: Block Memory Generator
- Component name: `verify_RAM`
- Memory type: Single Port RAM
- Width: 16
- Depth: 64
- Address width: 6
- Enable port: enabled
- Write enable width: 1
- Output register: disabled
- No initialization file needed

### `ila_0`

Use exactly 6 probes:

```text
probe0  16 bits  test_vector_in
probe1  20 bits  cnt_test
probe2   6 bits  verify_readback_addr_q
probe3  16 bits  verify_readback_data
probe4   1 bit   verify_readback_valid
probe5   1 bit   verify_ram_we
```

Recommended capture depth: 8192 or 16384.

Trigger suggestion:

```text
cnt_test != 0
```

Then release reset; the counter starts after the 16 input words have been loaded,
when the first instruction is fetched.

## Add Simulation Sources

For system-level simulation, add:

```text
tb/mcu_fft_system_tb.vhd
```

Run top:

```text
mcu_fft_system_tb
```

Expected note:

```text
mcu_fft_system_tb cnt_cycles 18
mcu_fft_system_tb passed
```

For core-only simulation, add:

```text
tb/mcu4_multicycle_core_tb.vhd
```

Run top:

```text
mcu4_multicycle_core_tb
```

For board-level simulation outside Vivado IP, add:

```text
tb/board_top_tb.vhd
```

Run top:

```text
board_top_tb
```

This testbench provides simple simulation stubs for `clk_wiz_0`, `test_ROM`,
`verify_RAM`, and `ila_0`, so do not add it to synthesis sources.

## Expected Board Result

Counter:

```text
cnt_test = 00012
```

Readback values:

```text
addr 00  F280
addr 01  E80A
addr 02  1A80
addr 03  FEA2
addr 04  E080
addr 05  16F6
addr 06  E680
addr 07  FA5E
addr 08  E900
addr 09  317C
addr 0A  2C00
addr 0B  1F8C
addr 0C  0B00
addr 0D  0C84
addr 0E  1600
addr 0F  D874
```

## Notes For Presentation

- This version uses four parallel worker cores rather than a memory-mapped butterfly accelerator.
- Each worker has its own PC, 32-bit instruction ROM, decoder, register file, ARM-style ALU/DSP execution, work-memory ports, and halt state.
- FFT data is stored in the MCU work memory `buf_a/buf_b`, implemented as a small multi-port register array.
- The worker core supports the course minimum ARM-style operations: `ADD`, `SUB`, `AND`, `ORR`, `MOV`, `LDR`, `STR`, `B`, and `BL`.
- Each butterfly is computed by worker instructions using ARM/ARM-DSP style operations: `LDR`, `STR`, `SADD16`, `SSUB16`, `SSAX`, `SMUAD`, `SMUSD`, `ASR`, and `PKHBT`.
- `SMUAD` and `SMUSD` are internally multi-cycle to shorten the DSP critical path for 200 MHz-class timing.
- Safe adjacent `MOV/MOV`, `LDR/LDR`, `STR/STR`, `SADD16/SSUB16`, and `PKHBT/SSUB16` instruction pairs can retire together; this is local dual issue, not a new FFT opcode.
- The worker also recognizes the current ARM-DSP dataflow windows `LDR/LDR/SADD16/SSUB16`, `SSAX/SADD16/SSUB16`, and `SMUAD/SMUSD/ASR/PKHBT`.
- The DSP-tail `ASR` result is precomputed and staged before it retires through the fused tail.
- The paired `STR/STR` second write data is staged in the worker decode register to avoid a direct register-file-to-buffer-write-data path.
- Local dual-issue eligibility is staged as a pair-kind register before the execute cycle.
- The `91/-91` twiddle constants are immediate constants initialized by worker instructions, not hidden constants in a special butterfly unit.
- The counter intentionally excludes input loading and output dump. It starts at
  the first instruction fetch and stops when the final instruction completes.
