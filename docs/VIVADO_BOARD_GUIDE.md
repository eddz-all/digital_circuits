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

`board_top` has two useful generics:

```text
PROGRAM_ID = 0, ACTIVE_CORES = 4  -- FFT mode, normal performance run
PROGRAM_ID = 1, ACTIVE_CORES = 1  -- basic instruction/PPT test mode
```

The default is FFT mode. The instruction ROM contents are explicit 32-bit VHDL
constant tables, not generated instructions.

Add this constraints file:

```text
constrs/board_top.xdc
```

If Vivado reports a duplicate clock constraint between `board_top.xdc` and `clk_wiz_0.xdc`, keep only one `create_clock` on `clk_in1`. This is a constraint cleanup issue, not an RTL issue.

## Basic Instruction Board Self-Test

For the basic instruction/PPT demonstration, use the separate board top:

```text
rtl/board_top_basic_test.vhd
```

Set `board_top_basic_test` as the top module. This top instantiates the full
`mcu4_multicycle_core` wrapper with:

```text
PROGRAM_ID   = 1
ACTIVE_CORES = 1
```

It initializes the core data memory through the generic `dmem_*` port, then runs
the `SELFTEST_ROM` program and reads the same data-memory port back to check the
results. It does not use `test_ROM`, `verify_RAM`, or `clk_wiz_0`. It runs from
the board 50 MHz input clock and contains a small synthesizable checker. The
checker keeps one signal high while the basic program is correct:

```text
test = 1  -- no error observed
test = 0  -- error latched; reset is required to retry
```

The checker watches generic MCU behavior rather than private registers:

- `illegal` must never assert.
- `data[1]` through `data[7]` must read back with the expected values after the `B .` completion sentinel.
- the second internal data region must still read back as zero.
- the worker must reach the `B .` completion sentinel before the timeout.
`pc_debug` and `instr_debug` remain useful trace signals, but the board-level
pass/fail bit does not depend on an exact cycle-by-cycle debug-word comparison.

Use this constraints file:

```text
constrs/board_top_basic_test.xdc
```

Generate one extra ILA IP for this top:

```text
Component name: ila_basic
Number of probes: 4
probe0 width:     1 bit  -- test
probe1 width:     1 bit  -- rst_btn/sys_rst
probe2 width:     4 bits -- error_code
probe3 width:     4 bits -- state_code
```

Recommended capture for presentation:

```text
Hold reset active, arm the ILA, then release reset.
Trigger on probe1 falling edge if edge trigger is available.
Otherwise trigger on probe1 == 1'b0, then confirm probe0 stays 1.
```

If `probe0` drops to 0, read `probe2`:

```text
0  no error latched
1  illegal instruction
2  timeout before halt
3  data[1] MOV result mismatch, expected 0x00000007
4  data[2] ADD result mismatch, expected 0x0000000A
5  data[3] SUB result mismatch, expected 0x00000007
6  data[4] AND result mismatch, expected 0x00000002
7  data[5] ORR result mismatch, expected 0x00000003
8  data[6] LDR result mismatch, expected 0x00000005
9  data[7] control-flow result mismatch, expected 0x0000000F
A  output/B address region was not zero
```

`probe3` shows the checker state:

```text
0 init work area A
1 init work area B
2 run
3 check data[1]
4 check data[2]
5 check data[3]
6 check data[4]
7 check data[5]
8 check data[6]
9 check data[7]
A check work area B
B done
```

Optional failure trigger:

```text
test == 0
```

If the captured `test` signal stays high for the whole run, the basic instruction
self-test passed on board. The same `test` signal is also exposed as a top-level
port and constrained to pin `G9`, matching the reference test pin.

## Generate IP

### `clk_wiz_0`

- IP: Clocking Wizard
- Component name: `clk_wiz_0`
- Input clock: 50 MHz
- Output clock: use 150 MHz as a conservative acceptance fallback. The latest
  high-performance build passes 170 MHz with positive WNS. For a separate
  maximum-frequency run, try 175 MHz first, then 178 MHz if timing remains
  positive. Each frequency must be justified by a fresh timing report.
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

Use exactly 4 probes for the lean FFT/performance build:

```text
probe0  16 bits  test_vector_in
probe1  20 bits  cnt_test
probe2   6 bits  verify_ram_addr
probe3  16 bits  verify_vector_out
```

Recommended capture depth: 8192 or 16384.

Trigger suggestion:

```text
cnt_test != 0
```

Then release reset; the counter starts after the 16 input words have been loaded,
when the first instruction is fetched. The output phase is visible as
`verify_ram_addr` sweeps through `0..15` while `verify_vector_out` carries the
16 FFT result half-words written into `verify_RAM`.

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
mcu_fft_system_tb cnt_cycles 22
mcu_fft_system_tb passed
```

For core-only simulation, add:

```text
tb/mcu4_multicycle_core_tb.vhd
tb/mcu4_multicycle_core_min_arm_tb.vhd
tb/mcu4_worker_core_min_arm_tb.vhd
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

## Common Vivado Refresh Issue

If synthesis reports:

```text
worker_pair_t is not declared
```

Vivado is still using an older copy of `mcu4_worker_instr_rom.vhd`. The current
RTL carries pair eligibility as `std_logic_vector(2 downto 0)` ports:

```vhdl
pair_kind      : out std_logic_vector(2 downto 0);
next_pair_kind : out std_logic_vector(2 downto 0)
```

Refresh the source file, then run:

```tcl
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 8
```

## Expected Board Result

Counter:

```text
cnt_test = 00016
```

Expected `verify_RAM` output values:

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
- Each worker has its own PC, 32-bit instruction ROM, decoder, register file, A32-decoded ALU/DSP execution, work-memory ports, and top-level `B .` completion detection.
- The worker instruction words are visible in `rtl/mcu4_worker_instr_rom.vhd` as `FFT_ROM_W0..FFT_ROM_W3` and `SELFTEST_ROM`.
- MCU data is stored in one unified 32-bit data memory. Current software uses byte address `0x40..0x5C` as work area A and `0x80..0x9C` as work area B/output; the FFT system wrapper packs/unpacks external 16-bit streams around these generic 32-bit words.
- The worker core supports the course minimum A32-encoded ARM operations: `ADD`, `SUB`, `AND`, `ORR`, `MOV`, `LDR`, `STR`, `B`, and `BL`.
- Each butterfly is computed by worker instructions using A32-encoded ARM/ARM-DSP operations: `LDR`, `STR`, `SADD16`, `SSUB16`, `SSAX`, `SMUAD`, `SMUSD`, `ASR`, and `PKHBT`.
- `SMUAD` and `SMUSD` are internally multi-cycle to shorten the DSP critical path for 200 MHz-class timing.
- Safe adjacent `MOV/MOV`, `LDR/LDR`, `STR/STR`, and `SADD16/SSUB16` instruction pairs can retire together when decoded dependencies make them safe; this is local dual issue, not a new FFT opcode.
- The worker does not recognize fixed FFT PC windows. Pairing and DSP overlap are selected from decoded instruction properties and register dependencies.
- The paired `STR/STR` second write data is staged in the worker decode register to avoid a direct register-file-to-buffer-write-data path.
- Local dual-issue eligibility is ROM-local predecoded as a 3-bit `pair_kind`
  code before the execute cycle. The code is carried as `std_logic_vector(2 downto 0)`
  rather than a custom enum port so Vivado synthesis does not depend on package
  type visibility for that interface.
- The `91/-91` twiddle constants are immediate constants initialized by worker instructions, not hidden constants in a special butterfly unit.
- The counter intentionally excludes input loading and output dump. It starts at
  the first instruction fetch and stops when the final instruction completes.
