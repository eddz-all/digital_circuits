# Vivado Board Guide

Use this guide for a new Vivado project based on:

```text
/home/huancheng/MCU/MCU_4cores_muticycle
```

## Add RTL Sources

Add these files as design sources in this order:

```text
rtl/mcu4_multi_pkg.vhd
rtl/mcu4_instr_rom.vhd
rtl/mcu4_decoder.vhd
rtl/mcu4_butterfly_lane.vhd
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
- Output clock: conservative board setting 30 MHz is fine
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

Then release reset; the counter starts only after the 16 input words have been loaded.

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
mcu_fft_system_tb cnt_cycles 58
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
cnt_test = 0003A
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

- This version supports the PPT-required baseline instruction families in the decoder: `ADD`, `SUB`, `AND`, `ORR`, `MOV`, `LDR`, `STR`, `B`, and `BL`.
- The FFT is launched by three visible `BL` instructions.
- Each `BL` jumps to a real instruction-ROM function body with four `DSP_BFLY_START` instructions, one `DSP_BFLY_WAIT`, and `MOV pc, lr`.
- The four butterfly lanes are multicycle DSP execution units, matching the PPT allowance for hardware acceleration and multicore parallelism.
- The W1/W3 complex multiply path is split into multiply and sum/subtract cycles to improve Fmax.
- The counter intentionally excludes input loading, following our final project decision. If the teacher insists on counting input reads from the PPT wording, add the input-load cycles separately.
