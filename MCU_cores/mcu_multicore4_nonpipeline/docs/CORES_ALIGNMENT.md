# Multicore4 board/system alignment with CORES

This note compares the 4-core non-pipelined board wrapper with the `CORES`
branch board-facing design. It is only an alignment note. It does not change
the 4-core RTL, the board wrapper, or the I/O contract.

## Compared designs

Current 4-core branch:

```text
MCU_cores/mcu_multicore4_nonpipeline/rtl/board_top.vhd
rtl/mcu_fft_system_multicore4.vhd
```

CORES branch reference:

```text
MCU_cores/mcu_8core_dsp/rtl/board_top.vhd
MCU_cores/mcu_8core_dsp/rtl/mcu_fft_system.vhd
```

## Synchronized board-facing contract

The two designs are aligned on the board-level data path:

```text
clk_in1 / rst_btn
clk_wiz_0
test_ROM
verify_RAM
cnt_start / cnt_stop
done / illegal
post-done verify_RAM readback for ILA observation
```

The memory windows also match:

```text
test_ROM[128..143] -> 16 input words
verify_RAM[0..15]  -> 16 output words
```

The teacher FFT output order is unchanged:

```text
verify_RAM[0..7]   -> real0..real7
verify_RAM[8..15]  -> imag0..imag7
```

The board IP width assumptions are aligned:

```text
test_ROM data width    = 16
test_ROM address width = 8
verify_RAM data width  = 16
verify_RAM addr width  = 6
cnt_test width         = 20
```

## Not file-level synchronized

The two branches are not drop-in identical at the source-file level.

CORES instantiates:

```text
mcu_fft_system
```

The 4-core board wrapper instantiates:

```text
entity work.mcu_fft_system_multicore4
```

The CORES `mcu_fft_system` generic list includes:

```text
MEM_FILE
CORE_ROM_DEPTH
INPUT_ROM_BASE
INPUT_COUNT
OUTPUT_COUNT
```

The 4-core `mcu_fft_system_multicore4` generic list includes:

```text
INPUT_COUNT
INPUT_ROM_BASE
OUTPUT_COUNT
```

This is intentional. The 4-core version is a radix-2 butterfly-parallel system,
not the CORES eight-worker DFT-style system.

## ILA difference

CORES uses a 6-probe `ila_0`:

```text
probe0 = test_vector_in
probe1 = cnt_test
probe2 = verify_readback_addr_q
probe3 = verify_readback_data
probe4 = verify_readback_valid
probe5 = verify_ram_we
```

The current 4-core board wrapper uses an 8-probe `ila_0`:

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

For the current 4-core board wrapper, create `ila_0` with 8 probes. If an
existing Vivado project only has the CORES 6-probe ILA, either regenerate the
ILA as 8 probes or use a separate CORES-compatible board wrapper.

## Counter boundary alignment

The 4-core board counter is aligned to the CORES branch counter style.

In the 4-core system:

```text
cnt_start = stage 0 dispatch after input loading and packing
cnt_stop  = final output word written in S_DUMP_OUTPUT
```

So the 4-core board counter includes:

```text
three butterfly stages
barrier/writeback overhead
16-word output dump
```

The external `test_ROM[128..143]` 16-word input loading phase still exists, but
it is not included in `cnt_test`, matching the CORES branch convention.

Current GHDL-observed values under this aligned counter boundary:

```text
multicore4 cnt_cycles = 33
CORES counted_cycles  = 60
```

## Practical board guidance

For the current 4-core branch, use these design sources:

```text
rtl/mcu_v1_butterfly_core.vhd
rtl/mcu_fft_system_multicore4.vhd
MCU_cores/mcu_multicore4_nonpipeline/rtl/board_top.vhd
```

Use this constraints file:

```text
MCU_cores/mcu_multicore4_nonpipeline/constrs/board_top.xdc
```

Expected board observation:

```text
done    = 1 after the run completes
illegal = 0
verify_RAM[0..15] matches FFT_output.coe order
cnt_test follows the 4-core counter boundary above
```

## Compatibility conclusion

The current 4-core board wrapper is synchronized with CORES at the board I/O
contract level, but not at the source-file and ILA-IP-shape level.

It is suitable for board bring-up when the Vivado project is configured for the
4-core wrapper's 8-probe ILA and `mcu_fft_system_multicore4` source list.

If strict CORES drop-in compatibility is required, add a thin compatibility
wrapper that exposes the `mcu_fft_system` entity name and the 6-probe ILA shape,
while still instantiating `mcu_fft_system_multicore4` internally.
