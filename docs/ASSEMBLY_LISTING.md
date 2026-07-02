# Worker Instruction Listing

The visible FFT instruction streams are implemented in:

```text
rtl/mcu4_worker_instr_rom.vhd
```

A readable assembly copy is also committed in:

```text
asm/mcu4_fft_workers_cnt22.s
```

That file documents the ROM program; the canonical instruction encodings are
the explicit 32-bit constant ROM entries in `rtl/mcu4_worker_instr_rom.vhd`.

The basic-instruction/PPT test listing is committed in:

```text
asm/mcu4_basic_selftest.s
```

Recommended generic settings:

```text
FFT mode:        PROGRAM_ID=0, ACTIVE_CORES=4
basic test mode: PROGRAM_ID=1, ACTIVE_CORES=1
```

There are four parallel worker cores. Each worker has its own PC, register file,
32-bit instruction ROM, decoder, ARM-style ALU/DSP operations, halt state, and
work-memory ports. The workers execute the same timed program shape with
lane-specific memory addresses.

The current counted result is:

```text
mcu_fft_system_tb cnt_cycles 22
cnt_test = 00016
```

The execution path is:

```text
fetch PC -> 32-bit instruction ROM -> fetch decode register
decode register -> register/ALU/DSP/load-store execute
```

`instr_debug` is now the actual 32-bit instruction ROM word, not a reverse
encoding of a pre-decoded control record.

Safe adjacent `MOV/MOV`, `LDR/LDR`, `STR/STR`, and `SADD16/SSUB16` pairs can
retire in the same counted cycle when decoded opcode, register, and memory-port
conditions make that safe. The instruction words and program order remain
visible; this is local worker scheduling, not a new FFT opcode and not a fixed
FFT-PC window.

The worker core also implements the course minimum ARM-style operations:

```asm
ADD
SUB
AND
ORR
MOV
LDR
STR
B
BL
```

The `SELFTEST_ROM` program explicitly exercises those operations, including
`B`, `BL`, and `MOV pc, lr`. Unused minimum operations do not add cycles to the
FFT program.

## Shared Prologue

Each worker first builds the fixed twiddle constants with immediate operands:

```asm
MOV    r0, #0
MOV    r1, #91
PKHBT  r3, r1, r1, LSL #16 ; 0x005B005B
SSUB16 r4, r0, r3          ; 0xFFA5FFA5
```

These constants are program immediates, not external input data and not hidden
butterfly hardware constants. The `-91/-91` packed value is derived with a
standard ARM DSP packed subtract, not with a custom twiddle instruction.

## FFT Stages

The 8-point radix-2 DIT FFT remains split across three stages:

```text
stage0: dmem_bank0 -> dmem_bank1, W0 butterflies
stage1: dmem_bank1 -> dmem_bank0, W0/W2 butterflies
stage2: dmem_bank0 -> dmem_bank1, W0/W1/W2/W3 butterflies
```

Each butterfly is performed by ARM/ARM-DSP style operations:

```asm
; W0
LDR
LDR
SADD16
SSUB16
STR
STR

; W2
LDR
LDR
SSAX
SADD16
SSUB16
STR
STR

; W1/W3
LDR
LDR
SMUAD/SMUSD
SMUSD/SMUAD
ASR
PKHBT
SADD16
SSUB16
STR
STR
```

Shorter lanes use `NOP` padding so all workers reach the next stage together.
There is no stage-start opcode or FFT-specific visible instruction.

## Timing-Only Microarchitecture

The following optimizations reduce `cnt` or improve timing without changing the
visible instruction program:

```text
fetch-side predecode registers
local dual issue for safe MOV/MOV, LDR/LDR, STR/STR, and SADD16/SSUB16 pairs
local pair pipeline for independent back-to-back SMUAD/SMUSD
ASR retirement overlapped with the second DSP writeback when dependencies allow
decode-stage operand staging for the second store in a safe STR/STR pair
prequalified pair-kind staging for local dual-issue control
```

The workers still retire the same ARM/ARM-DSP instruction stream in program
order. There is no hidden butterfly opcode and no hidden twiddle constant.
