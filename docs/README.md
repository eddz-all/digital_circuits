# MCU_4cores_muticycle

This folder is a self-contained four-core multicycle FFT MCU project.

## What This Version Does

- Loads only 16 input samples from `test_ROM[128..143]`.
- Starts `cnt_test` when the first instruction is fetched after all input
  samples have been loaded and packed.
- Executes a visible MCU instruction stream from `mcu4_instr_rom.vhd`.
- Uses one `BL fft_kernel` instruction to jump into a visible ROM-resident FFT function.
- Writes 16 FFT output words to `verify_RAM[0..15]` after the instruction
  counter has stopped.
- Exposes the same six ILA probes used by the current board-check flow.

The system-level GHDL test passes with:

```text
mcu_fft_system_tb cnt_cycles 35
mcu_fft_system_tb passed
```

So the expected board counter is:

```text
cnt_test = 00023
```

## File Map

RTL files:

```text
rtl/mcu4_multi_pkg.vhd
rtl/mcu4_instr_rom.vhd
rtl/mcu4_decoder.vhd
rtl/mcu4_butterfly_lane.vhd
rtl/mcu4_multicycle_core.vhd
rtl/mcu_fft_system.vhd
rtl/board_top.vhd
```

Testbenches:

```text
tb/mcu4_multicycle_core_tb.vhd
tb/mcu_fft_system_tb.vhd
tb/board_top_tb.vhd
```

Constraints:

```text
constrs/board_top.xdc
```

## Instruction Stream

The concrete 32-bit instructions are in `rtl/mcu4_instr_rom.vhd`:

```text
0  E3A00000  MOV  r0, #0
1  E2801001  ADD  r1, r0, #1
2  E0414001  SUB  r4, r1, r1
3  E201200F  AND  r2, r1, #15
4  E1823000  ORR  r3, r2, r0
5  EB000000  BL   fft_kernel
6  EAFFFFFE  B    halt
```

The `BL` target is a real function body made of visible ARM-style 32-bit
instructions. The four lanes are controlled as a memory-mapped accelerator.
`STR` writes one of three stage-start registers, `LDR` reads the done mask, and
`CMP/BNE` polls until all four lanes finish. After that, another visible `STR`
commits the stage result into the internal work buffer.

```text
7   E5800000  STR r0, [r0, #0]   ; start stage0
8   E5905004  LDR r5, [r0, #4]   ; done mask
9   E355000F  CMP r5, #15
10  1AFFFFFC  BNE stage0_wait
11  E5800010  STR r0, [r0, #16]  ; commit stage0
12  E5800008  STR r0, [r0, #8]   ; start stage1
...
22  E1A0F00E  MOV pc, lr
```

`r0` stays zero, so it is both the MMIO base address and the dummy write data.
The low address range is used for worker control and status:

```text
[r0, #0]   start stage0
[r0, #4]   read done mask
[r0, #8]   start stage1
[r0, #12]  start stage2
[r0, #16]  commit stage0
[r0, #20]  commit stage1
[r0, #24]  commit stage2
```

The stage writeback is explicit: the MCU issues one `STR` commit instruction
after each stage's done mask reaches `1111`.

The FFT data memory is the multi-port work-memory register array used by the
workers. It is still single-port addressable by normal ARM `LDR/STR`
instructions:

```text
[r0, #64]..[r0, #92]    buf_a[0..7]
[r0, #128]..[r0, #156]  buf_b[0..7]
```

The visible ROM keeps concrete examples:

```text
23  E5906040  LDR r6, [r0, #64]    ; read buf_a[0]
24  E5806080  STR r6, [r0, #128]   ; write buf_b[0]
```

## Architecture

`mcu4_multicycle_core.vhd` contains the MCU control path:

- PC register
- instruction ROM
- decoder
- 16 general-purpose registers
- condition flags
- branch/link handling with a real `BL` target and `MOV pc, lr` return
- ARM `LDR/STR` access to worker control registers and the FFT work memory
- multi-port FFT work memory `buf_a/buf_b`, also single-port accessible by `LDR/STR`
- four multicycle butterfly lanes

Each lane performs the FFT butterfly over several cycles. For W1 and W3 twiddle
factors it uses the same operation shape as ARM DSP instructions such as
`SMUAD`, `SMUSD`, `PKHBT`, `SADD16`, and `SSUB16`. The optimized lane uses four
parallel registered 16x16 products, followed by one sum/subtract cycle and one
pack cycle. This spends more DSP resources to cut the counted cycles.

This is not the older hardwired four-core FSM path. The top-level system only
loads input and dumps output; the FFT stages are launched by the MCU instruction
stream, and the stage functions themselves are visible ARM instruction sequences
in the instruction ROM. The former separate `data_mem` is removed: `buf_a/buf_b`
are the MCU's FFT data memory, implemented as a small multi-port register array
so four workers can read operands in parallel while `LDR/STR` still provide
single-word software access.

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
cd /home/huancheng/MCU/MCU_4cores_muticycle
export PATH="$HOME/tools/oss-cad-suite/bin:$PATH"
rm -f *.o e~*.o work-obj08.cf mcu4_multicycle_core_tb mcu_fft_system_tb
ghdl -a --std=08 rtl/mcu4_multi_pkg.vhd rtl/mcu4_instr_rom.vhd rtl/mcu4_decoder.vhd rtl/mcu4_butterfly_lane.vhd rtl/mcu4_multicycle_core.vhd rtl/mcu_fft_system.vhd tb/mcu4_multicycle_core_tb.vhd tb/mcu_fft_system_tb.vhd
ghdl -e --std=08 mcu4_multicycle_core_tb
ghdl -r --std=08 mcu4_multicycle_core_tb --assert-level=error
ghdl -e --std=08 mcu_fft_system_tb
ghdl -r --std=08 mcu_fft_system_tb --assert-level=error
```

Board-level simulation with IP stubs:

```bash
rm -f *.o e~*.o work-obj08.cf board_top_tb
ghdl -a --std=08 rtl/mcu4_multi_pkg.vhd rtl/mcu4_instr_rom.vhd rtl/mcu4_decoder.vhd rtl/mcu4_butterfly_lane.vhd rtl/mcu4_multicycle_core.vhd rtl/mcu_fft_system.vhd rtl/board_top.vhd tb/board_top_tb.vhd
ghdl -e --std=08 board_top_tb
ghdl -r --std=08 board_top_tb --assert-level=error
```
