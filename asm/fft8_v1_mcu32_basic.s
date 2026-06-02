; 8-point forward complex FFT for the first MCU32 interface.
;
; Interface:
;   INPUT_BASE   = 0
;   WORK_BASE    = 256
;   OUTPUT_BASE  = 512
;
; Data layout:
;   input/output program view: 32-bit slots, real/imag interleaved, +4 stride
;   work RAM internal data:     32-bit signed, real/imag interleaved, +4 stride
;
; Instruction subset used:
;   MOV, ADD, SUB, LDR, STR, B, MUL, ASR
;
; Transform:
;   radix-2 DIF forward FFT, fully unrolled
;   every butterfly divides by 2, so output = FFT(input) / 8
;
; Output order:
;   bit-reversal order: X0, X4, X2, X6, X1, X5, X3, X7

START:
    MOV R8, #0
    MOV R9, #256
    MOV R10, #512
    MOV R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #2695

; Copy input slots into 32-bit work RAM.
    LDR R0, [R8 + 0]
    STR R0, [R9 + 0]
    LDR R0, [R8 + 4]
    STR R0, [R9 + 4]
    LDR R0, [R8 + 8]
    STR R0, [R9 + 8]
    LDR R0, [R8 + 12]
    STR R0, [R9 + 12]
    LDR R0, [R8 + 16]
    STR R0, [R9 + 16]
    LDR R0, [R8 + 20]
    STR R0, [R9 + 20]
    LDR R0, [R8 + 24]
    STR R0, [R9 + 24]
    LDR R0, [R8 + 28]
    STR R0, [R9 + 28]
    LDR R0, [R8 + 32]
    STR R0, [R9 + 32]
    LDR R0, [R8 + 36]
    STR R0, [R9 + 36]
    LDR R0, [R8 + 40]
    STR R0, [R9 + 40]
    LDR R0, [R8 + 44]
    STR R0, [R9 + 44]
    LDR R0, [R8 + 48]
    STR R0, [R9 + 48]
    LDR R0, [R8 + 52]
    STR R0, [R9 + 52]
    LDR R0, [R8 + 56]
    STR R0, [R9 + 56]
    LDR R0, [R8 + 60]
    STR R0, [R9 + 60]

; Stage 1, butterfly (0,4), twiddle W8^0 = 1.
    LDR R0, [R9 + 0]
    LDR R1, [R9 + 4]
    LDR R2, [R9 + 32]
    LDR R3, [R9 + 36]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 0]
    STR R6, [R9 + 4]
    STR R5, [R9 + 32]
    STR R7, [R9 + 36]

; Stage 1, butterfly (1,5), twiddle W8^1 = 0.7071 - j0.7071.
    LDR R0, [R9 + 8]
    LDR R1, [R9 + 12]
    LDR R2, [R9 + 40]
    LDR R3, [R9 + 44]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 8]
    STR R6, [R9 + 12]
    ADD R11, R5, R7
    MUL R11, R11, R12
    ASR R11, R11, #15
    STR R11, [R9 + 40]
    SUB R11, R7, R5
    MUL R11, R11, R12
    ASR R11, R11, #15
    STR R11, [R9 + 44]

; Stage 1, butterfly (2,6), twiddle W8^2 = -j.
    LDR R0, [R9 + 16]
    LDR R1, [R9 + 20]
    LDR R2, [R9 + 48]
    LDR R3, [R9 + 52]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 16]
    STR R6, [R9 + 20]
    STR R7, [R9 + 48]
    MOV R11, #0
    SUB R11, R11, R5
    STR R11, [R9 + 52]

; Stage 1, butterfly (3,7), twiddle W8^3 = -0.7071 - j0.7071.
    LDR R0, [R9 + 24]
    LDR R1, [R9 + 28]
    LDR R2, [R9 + 56]
    LDR R3, [R9 + 60]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 24]
    STR R6, [R9 + 28]
    SUB R11, R7, R5
    MUL R11, R11, R12
    ASR R11, R11, #15
    STR R11, [R9 + 56]
    ADD R11, R5, R7
    MUL R11, R11, R12
    ASR R11, R11, #15
    MOV R0, #0
    SUB R11, R0, R11
    STR R11, [R9 + 60]

; Stage 2, butterfly (0,2), twiddle W4^0 = 1.
    LDR R0, [R9 + 0]
    LDR R1, [R9 + 4]
    LDR R2, [R9 + 16]
    LDR R3, [R9 + 20]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 0]
    STR R6, [R9 + 4]
    STR R5, [R9 + 16]
    STR R7, [R9 + 20]

; Stage 2, butterfly (1,3), twiddle W4^1 = -j.
    LDR R0, [R9 + 8]
    LDR R1, [R9 + 12]
    LDR R2, [R9 + 24]
    LDR R3, [R9 + 28]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 8]
    STR R6, [R9 + 12]
    STR R7, [R9 + 24]
    MOV R11, #0
    SUB R11, R11, R5
    STR R11, [R9 + 28]

; Stage 2, butterfly (4,6), twiddle W4^0 = 1.
    LDR R0, [R9 + 32]
    LDR R1, [R9 + 36]
    LDR R2, [R9 + 48]
    LDR R3, [R9 + 52]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 32]
    STR R6, [R9 + 36]
    STR R5, [R9 + 48]
    STR R7, [R9 + 52]

; Stage 2, butterfly (5,7), twiddle W4^1 = -j.
    LDR R0, [R9 + 40]
    LDR R1, [R9 + 44]
    LDR R2, [R9 + 56]
    LDR R3, [R9 + 60]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 40]
    STR R6, [R9 + 44]
    STR R7, [R9 + 56]
    MOV R11, #0
    SUB R11, R11, R5
    STR R11, [R9 + 60]

; Stage 3, butterfly (0,1), twiddle W2^0 = 1.
    LDR R0, [R9 + 0]
    LDR R1, [R9 + 4]
    LDR R2, [R9 + 8]
    LDR R3, [R9 + 12]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 0]
    STR R6, [R9 + 4]
    STR R5, [R9 + 8]
    STR R7, [R9 + 12]

; Stage 3, butterfly (2,3), twiddle W2^0 = 1.
    LDR R0, [R9 + 16]
    LDR R1, [R9 + 20]
    LDR R2, [R9 + 24]
    LDR R3, [R9 + 28]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 16]
    STR R6, [R9 + 20]
    STR R5, [R9 + 24]
    STR R7, [R9 + 28]

; Stage 3, butterfly (4,5), twiddle W2^0 = 1.
    LDR R0, [R9 + 32]
    LDR R1, [R9 + 36]
    LDR R2, [R9 + 40]
    LDR R3, [R9 + 44]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 32]
    STR R6, [R9 + 36]
    STR R5, [R9 + 40]
    STR R7, [R9 + 44]

; Stage 3, butterfly (6,7), twiddle W2^0 = 1.
    LDR R0, [R9 + 48]
    LDR R1, [R9 + 52]
    LDR R2, [R9 + 56]
    LDR R3, [R9 + 60]
    ADD R4, R0, R2
    ASR R4, R4, #1
    SUB R5, R0, R2
    ASR R5, R5, #1
    ADD R6, R1, R3
    ASR R6, R6, #1
    SUB R7, R1, R3
    ASR R7, R7, #1
    STR R4, [R9 + 48]
    STR R6, [R9 + 52]
    STR R5, [R9 + 56]
    STR R7, [R9 + 60]

; Write output to verify_RAM, program-view +4 stride.
; The sequential work entries are already in bit-reversal order.
    LDR R0, [R9 + 0]
    STR R0, [R10 + 0]
    LDR R0, [R9 + 4]
    STR R0, [R10 + 4]
    LDR R0, [R9 + 8]
    STR R0, [R10 + 8]
    LDR R0, [R9 + 12]
    STR R0, [R10 + 12]
    LDR R0, [R9 + 16]
    STR R0, [R10 + 16]
    LDR R0, [R9 + 20]
    STR R0, [R10 + 20]
    LDR R0, [R9 + 24]
    STR R0, [R10 + 24]
    LDR R0, [R9 + 28]
    STR R0, [R10 + 28]
    LDR R0, [R9 + 32]
    STR R0, [R10 + 32]
    LDR R0, [R9 + 36]
    STR R0, [R10 + 36]
    LDR R0, [R9 + 40]
    STR R0, [R10 + 40]
    LDR R0, [R9 + 44]
    STR R0, [R10 + 44]
    LDR R0, [R9 + 48]
    STR R0, [R10 + 48]
    LDR R0, [R9 + 52]
    STR R0, [R10 + 52]
    LDR R0, [R9 + 56]
    STR R0, [R10 + 56]
    LDR R0, [R9 + 60]
    STR R0, [R10 + 60]

DONE:
    B DONE
