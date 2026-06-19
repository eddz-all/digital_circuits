# MCU multicore4 non-pipeline board wrapper

This directory contains board-facing files for the existing 4-core
non-pipelined radix-2 FFT design.

It does not copy or modify the 4-core implementation. Add the existing root RTL
files to the board project, then add the wrapper in this directory:

```text
../../rtl/mcu_v1_butterfly_core.vhd
../../rtl/mcu_fft_system_multicore4.vhd
rtl/board_top.vhd
```

## Architecture boundary

The board wrapper instantiates the existing `mcu_fft_system_multicore4` system.
It only provides board-level plumbing:

```text
clk_wiz_0 -> system clock/reset
test_ROM  -> FFT_input.coe data source
mcu_fft_system_multicore4 -> current 4-core FFT system
verify_RAM -> FFT_output.coe-compatible result sink
ila_0 -> counter and verify_RAM readback observation
```

The 4-core compute path, stage mapping, twiddle modes, ping-pong buffers, and
`cnt_start` / `cnt_stop` behavior remain owned by the existing root RTL.

## COE contract

The wrapper keeps the 2026 teacher-sample layout:

```text
test_ROM[128..135] -> signal real Q5
test_ROM[136..143] -> signal imag Q5

verify_RAM[0..7]   -> output real Q12, natural order
verify_RAM[8..15]  -> output imag Q12, natural order
```

`INPUT_ROM_BASE` is fixed to `128` in `board_top.vhd`. If a board project uses
a signal-only COE file instead of the full teacher `FFT_input.coe`, change only
the generic map in this wrapper, not the 4-core RTL.

## Counter boundary

`cnt_test` mirrors the existing 4-core system counter pulses:

```text
cnt_start: stage 0 dispatch after all input words are loaded and packed
cnt_stop : final verify_RAM output slot written by S_DUMP_OUTPUT
```

So the board counter follows the CORES-style execution/output boundary. It
includes three butterfly stages, barrier/writeback overhead, and the 16-slot output dump. It
does not include the external 16-word `test_ROM[128..143]` input loading phase.
does not include reset time or post-done verify_RAM readback for ILA display.

The current local GHDL system test for the underlying 4-core system reports:

```text
mcu_fft_system_multicore4_tb cnt_cycles 33
```

## ILA probes

The wrapper matches the existing board project's 8-probe `ila_0` shape:

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

Recommended trigger:

```text
probe4 == 1
```

This captures the post-run readback of `verify_RAM[0..15]`.
