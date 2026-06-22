# MCU_4cores_muticycle

This folder is a self-contained four-core multicycle FFT MCU project.

## What This Version Does

- Loads only 16 input samples from `test_ROM[128..143]`.
- Starts `cnt_test` after all input samples have been loaded and packed.
- Executes a visible MCU instruction stream from `mcu4_instr_rom.vhd`.
- Uses `BL fft_stageN_kernel` instructions to jump into visible ROM-resident stage functions.
- Writes 16 FFT output words to `verify_RAM[0..15]`.
- Exposes the same six ILA probes used by the current board-check flow.

The system-level GHDL test passes with:

```text
mcu_fft_system_tb cnt_cycles 58
mcu_fft_system_tb passed
```

So the expected board counter is:

```text
cnt_test = 0003A
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
5  EB000002  BL   fft_stage0_kernel
6  EB000007  BL   fft_stage1_kernel
7  EB00000C  BL   fft_stage2_kernel
8  EAFFFFFE  B    halt
```

Each `BL` target is a real function body made of visible 32-bit instructions:

```text
9   ED800000  DSP_BFLY_START stage0 lane0
10  ED820000  DSP_BFLY_START stage0 lane1
11  ED840000  DSP_BFLY_START stage0 lane2
12  ED860000  DSP_BFLY_START stage0 lane3
13  ED600000  DSP_BFLY_WAIT  stage0
14  E1A0F00E  MOV pc, lr

15  ED880000  DSP_BFLY_START stage1 lane0
16  ED8A0000  DSP_BFLY_START stage1 lane1
17  ED8C0000  DSP_BFLY_START stage1 lane2
18  ED8E0000  DSP_BFLY_START stage1 lane3
19  ED680000  DSP_BFLY_WAIT  stage1
20  E1A0F00E  MOV pc, lr

21  ED900000  DSP_BFLY_START stage2 lane0
22  ED920000  DSP_BFLY_START stage2 lane1
23  ED940000  DSP_BFLY_START stage2 lane2
24  ED960000  DSP_BFLY_START stage2 lane3
25  ED700000  DSP_BFLY_WAIT  stage2
26  E1A0F00E  MOV pc, lr
```

Addresses 27 to 31 keep concrete `LDR`, `STR`, and DSP-extension examples for report/inspection.

## Architecture

`mcu4_multicycle_core.vhd` contains the MCU control path:

- PC register
- instruction ROM
- decoder
- 16 general-purpose registers
- condition flags
- branch/link handling with real `BL` targets and `MOV pc, lr` returns
- four multicycle butterfly lanes

Each lane performs the FFT butterfly over several cycles. For W1 and W3 twiddle factors it uses the same operation shape as ARM DSP instructions such as `SMUAD`, `SMUSD`, `PKHBT`, `SADD16`, and `SSUB16`. The complex multiply path is split into a multiply-register cycle and a sum/subtract cycle, reducing the critical path compared with doing multiply and add in the same cycle.

This is not the older hardwired four-core FSM path. The top-level system only loads input and dumps output; the FFT stages are launched by the MCU instruction stream, and the stage functions themselves are visible instructions in the instruction ROM.

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
