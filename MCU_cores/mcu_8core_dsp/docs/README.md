# MCU 8-Core DSP Version

This version keeps the board-facing shape of the v1 project while replacing
the core internals with eight single-cycle DSP workers.

## Files

```text
rtl/mcu_8core_dsp_pkg.vhd      Shared instruction encoders, DFT constants, DSP helpers
rtl/mcu_8core_instr_rom.vhd    Per-worker instruction ROM interface
rtl/mcu_8core_decoder.vhd      Instruction decoder
rtl/mcu_8core_regfile.vhd      16 x 32-bit register file
rtl/mcu_8core_dsp_worker.vhd   One single-cycle worker core tying ROM/decode/regfile/execute together
rtl/mcu_v1_core.vhd            8-worker wrapper with the v1-compatible core port
rtl/mcu_fft_system.vhd         16-input system wrapper with execute-phase counter start
rtl/board_top.vhd              Board top paired with this 8-core system
tb/mcu_8core_core_tb.vhd       Direct core testbench
tb/mcu_fft_system_tb.vhd       test_ROM -> system -> verify_RAM testbench
```

## Architecture

The wrapper instantiates eight workers:

```text
worker0 -> X0
worker1 -> X1
...
worker7 -> X7
```

Each worker has its own PC, instruction ROM, decoder, register file, input
copy, output pair, and single-cycle instruction executor. Input writes are
broadcast to all workers, so there is no shared RAM arbitration during
execution.

Inside one worker:

```text
PC -> instruction ROM -> decoder -> register file reads
                         -> execute/load/store/writeback -> PC update
```

## Instruction Subset

The concrete 32-bit worker program is stored in `WORKER_PROGRAM` inside
`rtl/mcu_8core_dsp_pkg.vhd`. `rtl/mcu_8core_instr_rom.vhd` reads that table by
PC index and outputs the instruction word.

The worker program currently uses:

```text
MOVI
LDR
STR
SMLSD
SMLADX
SSAT
B
```

The executor also implements:

```text
MUL
MLA
```

The packed complex format is:

```text
word[15:0]  = real, signed 16-bit
word[31:16] = imag, signed 16-bit
```

For each sample:

```text
SMLSD   acc_real, x, w, acc_real   -- xr*wr - xi*wi
SMLADX  acc_imag, x, w, acc_imag   -- xr*wi + xi*wr
```

## Input and Coefficients

The DFT coefficient matrix is hard-coded in `mcu_8core_dsp_pkg.vhd`.
The external ROM is only read 16 times.

Default `mcu_fft_system` behavior reads the teacher COE signal window:

```text
test_ROM[128..135] -> xr0..xr7
test_ROM[136..143] -> xi0..xi7
```

The core stores these as local input slots:

```text
input_mem[0..7]  = real samples
input_mem[8..15] = imag samples
```

If a board project uses `FFT_signal_only.coe`, set:

```text
INPUT_ROM_BASE => 0
```

## Counter Boundary

The load phase is not counted.

`cnt_start` pulses in `S_START_RUN`, after all 16 inputs have been loaded and
just before the workers begin executing instructions. `cnt_stop` pulses when
the final output word is written to `verify_RAM`.

The current GHDL system test reports:

```text
counted_cycles=60
```

The count is:

```text
42 cycles  worker instruction execution
 2 cycles  start/finish visibility through the system FSM
16 cycles  output dump to verify_RAM, 16 outputs * 1 state
--------
60 cycles
```

So this count includes eight-core instruction execution and the existing
`mcu_fft_system` output dump sequence, but excludes external input loading.
If the score definition only wants "instruction execution" and does not count
writing `verify_RAM`, move `cnt_stop` from the final dump write to the moment
`core_halted` is observed.

## ILA Mapping

The paired `board_top.vhd` expects a 6-probe `ila_0` IP. Configure the probe
widths as 16, 20, 6, 16, 1, 1:

```text
probe0 = test_vector_in          -- current test_ROM data bus
probe1 = cnt_test
probe2 = verify_readback_addr_q
probe3 = verify_readback_data
probe4 = verify_readback_valid
probe5 = verify_ram_we
```

## GHDL

Run from `MCU_cores/mcu_8core_dsp`:

```bash
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
ghdl --clean
ghdl -a --std=08 \
  rtl/mcu_8core_dsp_pkg.vhd \
  rtl/mcu_8core_instr_rom.vhd \
  rtl/mcu_8core_decoder.vhd \
  rtl/mcu_8core_regfile.vhd \
  rtl/mcu_8core_dsp_worker.vhd \
  rtl/mcu_v1_core.vhd \
  rtl/mcu_fft_system.vhd \
  rtl/board_top.vhd \
  tb/mcu_8core_core_tb.vhd \
  tb/mcu_fft_system_tb.vhd
ghdl -e --std=08 mcu_8core_core_tb
ghdl -r --std=08 mcu_8core_core_tb --assert-level=error
ghdl -e --std=08 mcu_fft_system_tb
ghdl -r --std=08 mcu_fft_system_tb --assert-level=error
```
