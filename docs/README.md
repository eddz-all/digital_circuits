# MCU_4cores_muticycle

This folder is a self-contained four-worker ARM/ARM-DSP instruction FFT MCU
project.

## What This Version Does

- Loads only 16 input samples from `test_ROM[128..143]` in the outer system.
- Starts `cnt_test` when the core instruction-run window begins.
- Runs four parallel worker cores. Each worker has its own PC, register file,
  instruction decode, ARM-style ALU/DSP execution, and halt state.
- Computes each FFT butterfly through visible ARM/ARM-DSP style worker
  instructions, not through a single-purpose butterfly hardware block.
- Writes 16 FFT output words to `verify_RAM[0..15]` after the instruction
  counter has stopped.
- Exposes the same six ILA probes used by the board-check flow.

The system-level GHDL test passes with:

```text
mcu_fft_system_tb cnt_cycles 28
mcu_fft_system_tb passed
```

So the expected board counter is:

```text
cnt_test = 0001C
```

## File Map

RTL files:

```text
rtl/mcu4_multi_pkg.vhd
rtl/mcu4_worker_core.vhd
rtl/mcu4_multicycle_core.vhd
rtl/mcu_fft_system.vhd
rtl/board_top.vhd
```

Testbenches:

```text
tb/mcu4_multicycle_core_tb.vhd
tb/mcu4_worker_core_min_arm_tb.vhd
tb/mcu_fft_system_tb.vhd
tb/board_top_tb.vhd
```

Constraints:

```text
constrs/board_top.xdc
```

## Architecture

`mcu_fft_system.vhd` remains the outer I/O wrapper:

- input load from `test_ROM[128..143]` into the core while the core is held in
  reset;
- `cnt_start` asserted only when the worker instruction-run window begins;
- output dump to `verify_RAM[0..15]` only after `cnt_stop`.

`mcu4_multicycle_core.vhd` contains the shared FFT work memory:

```text
buf_a[0..7]
buf_b[0..7]
```

Each word is packed complex data:

```text
word[15:0]  = real
word[31:16] = imag
```

`mcu4_worker_core.vhd` implements four parallel worker cores. The worker core
supports the minimum ARM-style instruction set required by the course brief:

```text
ADD, SUB, AND, ORR, MOV, LDR, STR, B, BL
```

The FFT worker program keeps using the shorter ARM/ARM-DSP operation sequence
needed for the FFT:

```text
MOV, LDR, STR, SADD16, SSUB16, SSAX, SMUAD, SMUSD, ASR, PKHBT
```

The worker execution path is:

```text
pc_reg -> 32-bit worker instruction ROM -> decode_worker_instr -> execute
```

`instr_debug` directly exposes the 32-bit instruction word fetched from the
worker ROM. The decoder parses `op`, `rd`, `rn`, `rm`, immediate fields, and
`buf_a/buf_b` load-store addresses from that instruction word.

The encoding is an ARM/ARM-DSP style 32-bit instruction encoding. Base
instructions use ARM-like words such as `E3Axxxxx`, `E590xxxx`, and `EAxxxxxx`;
the packed DSP instructions use project-local ARM-DSP style fixed patterns that
the decoder recognizes explicitly.

The fixed twiddle constants `91/-91` are immediate constants in the worker
program. `+91/+91` is built with `PKHBT`, and `-91/-91` is built with
`SSUB16` from zero and `+91/+91`; the constants are not read from external input
or hidden inside a dedicated butterfly unit.

## Expected Output

`verify_RAM[0..15]` should be:

```text
F280 E80A 1A80 FEA2 E080 16F6 E680 FA5E
E900 317C 2C00 1F8C 0B00 0C84 1600 D874
```

Signed decimal:

```text
-3456 -6134 6784 -350 -8064 5878 -6528 -1442
-5888 12668 11264 8076 2816 3204 5632 -10124
```

## Local Simulation

```bash
rm -rf /tmp/digital_circuits_ghdl_mcu4
mkdir -p /tmp/digital_circuits_ghdl_mcu4

ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 \
  rtl/mcu4_multi_pkg.vhd \
  rtl/mcu4_worker_core.vhd \
  rtl/mcu4_multicycle_core.vhd \
  rtl/mcu_fft_system.vhd \
  tb/mcu4_worker_core_min_arm_tb.vhd \
  tb/mcu4_multicycle_core_tb.vhd \
  tb/mcu_fft_system_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 mcu4_worker_core_min_arm_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 mcu4_worker_core_min_arm_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 mcu4_multicycle_core_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 mcu4_multicycle_core_tb --assert-level=error

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 mcu_fft_system_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 mcu_fft_system_tb --assert-level=error
```

Board-level simulation with IP stubs:

```bash
ghdl -a --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 \
  rtl/mcu4_multi_pkg.vhd \
  rtl/mcu4_worker_core.vhd \
  rtl/mcu4_multicycle_core.vhd \
  rtl/mcu_fft_system.vhd \
  rtl/board_top.vhd \
  tb/board_top_tb.vhd

ghdl -e --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 board_top_tb
ghdl -r --std=08 --workdir=/tmp/digital_circuits_ghdl_mcu4 board_top_tb --assert-level=error
```
