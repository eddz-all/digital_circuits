; 8-point forward complex FFT, packed DSP accelerated version.
;
; Interface:
;   INPUT_BASE   = 0
;   OUTPUT_BASE  = 512
;
; External data layout stays unchanged:
;   input/output program view: 16 signed values in 32-bit slots, +4 stride
;
; Internal packed format:
;   one 32-bit register holds one complex sample
;   low  halfword = real, high halfword = imag
;
; Transform:
;   radix-2 DIF forward FFT, fully unrolled
;   every butterfly divides by 2, so output = FFT(input) / 8
;
; Output order:
;   bit-reversal order: X0, X4, X2, X6, X1, X5, X3, X7

START:
    MOV R8, #0
    MOV R10, #512
    MOV R13, #0
    MOV R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #2695
    PKHBT R12, R12, R12, LSL #16

; Pack external real/imag slots into R0..R7.
    LDR R9, [R8 + 0]
    LDR R11, [R8 + 4]
    PKHBT R0, R9, R11, LSL #16
    LDR R9, [R8 + 8]
    LDR R11, [R8 + 12]
    PKHBT R1, R9, R11, LSL #16
    LDR R9, [R8 + 16]
    LDR R11, [R8 + 20]
    PKHBT R2, R9, R11, LSL #16
    LDR R9, [R8 + 24]
    LDR R11, [R8 + 28]
    PKHBT R3, R9, R11, LSL #16
    LDR R9, [R8 + 32]
    LDR R11, [R8 + 36]
    PKHBT R4, R9, R11, LSL #16
    LDR R9, [R8 + 40]
    LDR R11, [R8 + 44]
    PKHBT R5, R9, R11, LSL #16
    LDR R9, [R8 + 48]
    LDR R11, [R8 + 52]
    PKHBT R6, R9, R11, LSL #16
    LDR R9, [R8 + 56]
    LDR R11, [R8 + 60]
    PKHBT R7, R9, R11, LSL #16

; Stage 1, butterfly (0,4), W8^0 = 1.
    SHADD16 R8, R0, R4
    SHSUB16 R4, R0, R4
    MOV R0, R8

; Stage 1, butterfly (1,5), W8^1 = 0.7071 - j0.7071.
    SHADD16 R8, R1, R5
    SHSUB16 R5, R1, R5
    MOV R1, R8
    SMUAD R8, R5, R12
    SMUSD R9, R5, R12
    SUB R9, R13, R9
    ASR R8, R8, #15
    ASR R9, R9, #15
    PKHBT R5, R8, R9, LSL #16

; Stage 1, butterfly (2,6), W8^2 = -j.
    SHADD16 R8, R2, R6
    SHSUB16 R6, R2, R6
    MOV R2, R8
    SXTH R8, R6
    ASR R9, R6, #16
    SUB R8, R13, R8
    PKHBT R6, R9, R8, LSL #16

; Stage 1, butterfly (3,7), W8^3 = -0.7071 - j0.7071.
    SHADD16 R8, R3, R7
    SHSUB16 R7, R3, R7
    MOV R3, R8
    SMUAD R8, R7, R12
    SMUSD R9, R7, R12
    SUB R9, R13, R9
    ASR R9, R9, #15
    ASR R8, R8, #15
    SUB R8, R13, R8
    PKHBT R7, R9, R8, LSL #16

; Stage 2, butterfly (0,2), W4^0 = 1.
    SHADD16 R8, R0, R2
    SHSUB16 R2, R0, R2
    MOV R0, R8

; Stage 2, butterfly (1,3), W4^1 = -j.
    SHADD16 R8, R1, R3
    SHSUB16 R3, R1, R3
    MOV R1, R8
    SXTH R8, R3
    ASR R9, R3, #16
    SUB R8, R13, R8
    PKHBT R3, R9, R8, LSL #16

; Stage 2, butterfly (4,6), W4^0 = 1.
    SHADD16 R8, R4, R6
    SHSUB16 R6, R4, R6
    MOV R4, R8

; Stage 2, butterfly (5,7), W4^1 = -j.
    SHADD16 R8, R5, R7
    SHSUB16 R7, R5, R7
    MOV R5, R8
    SXTH R8, R7
    ASR R9, R7, #16
    SUB R8, R13, R8
    PKHBT R7, R9, R8, LSL #16

; Stage 3, final 2-point butterflies.
    SHADD16 R8, R0, R1
    SHSUB16 R1, R0, R1
    MOV R0, R8
    SHADD16 R8, R2, R3
    SHSUB16 R3, R2, R3
    MOV R2, R8
    SHADD16 R8, R4, R5
    SHSUB16 R5, R4, R5
    MOV R4, R8
    SHADD16 R8, R6, R7
    SHSUB16 R7, R6, R7
    MOV R6, R8

; Write real/imag output slots to verify_RAM, program-view +4 stride.
    STR R0, [R10 + 0]
    ASR R8, R0, #16
    STR R8, [R10 + 4]
    STR R1, [R10 + 8]
    ASR R8, R1, #16
    STR R8, [R10 + 12]
    STR R2, [R10 + 16]
    ASR R8, R2, #16
    STR R8, [R10 + 20]
    STR R3, [R10 + 24]
    ASR R8, R3, #16
    STR R8, [R10 + 28]
    STR R4, [R10 + 32]
    ASR R8, R4, #16
    STR R8, [R10 + 36]
    STR R5, [R10 + 40]
    ASR R8, R5, #16
    STR R8, [R10 + 44]
    STR R6, [R10 + 48]
    ASR R8, R6, #16
    STR R8, [R10 + 52]
    STR R7, [R10 + 56]
    ASR R8, R7, #16
    STR R8, [R10 + 60]

DONE:
    B DONE
