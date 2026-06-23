# Worker Instruction Listing

The visible FFT instruction streams are implemented in:

```text
rtl/mcu4_worker_core.vhd
```

There are four parallel worker cores. Each worker has its own PC, register file,
instruction decode, ARM-style ALU/DSP operations, halt state, and work-memory
ports. The workers execute the same timed program shape with lane-specific
memory addresses.

The executed path is not a pre-decoded `worker_instr_t` table. Each worker uses:

```text
pc_reg -> worker_instr_rom(wid, pc) -> 32-bit instr_word
       -> decode_worker_instr(instr_word) -> execute
```

`instr_debug` is the ROM output `instr_word`, not a reverse-encoded display
value. The decoder recognizes ARM/ARM-DSP style 32-bit instruction patterns and
extracts `op`, registers, immediates, and `buf_a/buf_b` load-store indexes from
the instruction word.

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

These extra minimum operations are supported by the core, but unused operations
do not add cycles to the FFT program.

The DSP encodings are project-local ARM-DSP style 32-bit patterns, not a claim
of full official ARM binary compatibility. They are decoded from `instr_word`
before execution.

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
stage0: buf_a -> buf_b, W0 butterflies
stage1: buf_b -> buf_a, W0/W2 butterflies
stage2: buf_a -> buf_b, W0/W1/W2/W3 butterflies
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
