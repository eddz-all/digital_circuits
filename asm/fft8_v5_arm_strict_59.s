; 8-point forward complex FFT, V5 ARM-strict 59.
;
; Constraints:
;   ARM-real mnemonic only.
;   single-core, single-issue, single-cycle.
;   exact packed DSP fixed model.
;
; Internal packed format:
;   low16 = real, high16 = imag.

START:
    MOV R14, #0
    MOV R13, #0

; twiddle +23170 packed in R12.
    MOV R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #2695
    PKHBT R12, R12, R12, LSL #16

; bias 32767 in R11 for exact SMLAD W3 sign handling.
    MOV R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #4095
    ADD R11, R11, #7

; Load and pack external real/imag slots into packed complex registers.
; The split preserves R11 bias and leaves enough temporary registers.
    LDMIA R14!, {R0-R10}
    PKHBT R0, R0, R1, LSL #16
    PKHBT R1, R2, R3, LSL #16
    PKHBT R2, R4, R5, LSL #16
    PKHBT R3, R6, R7, LSL #16
    PKHBT R4, R8, R9, LSL #16
    LDMIA R14!, {R5-R9}
    PKHBT R5, R10, R5, LSL #16
    PKHBT R6, R6, R7, LSL #16
    PKHBT R7, R8, R9, LSL #16
    SSUB16 R14, R13, R12

; Stage 1, butterfly (0,4), W8^0.
    SHADD16 R8, R0, R4
    SHSUB16 R4, R0, R4

; Stage 1, butterfly (1,5), W8^1.
    SHADD16 R9, R1, R5
    SHSUB16 R5, R1, R5
    SMUAD R0, R5, R12
    SMUSD R10, R5, R14
    ASR R0, R0, #15
    ASR R10, R10, #15
    PKHBT R5, R0, R10, LSL #16

; Stage 1, butterfly (2,6), W8^2 = -j.
    SHADD16 R0, R2, R6
    SHSUB16 R6, R2, R6
    SSAX R6, R13, R6

; Stage 1, butterfly (3,7), W8^3.
    SHADD16 R1, R3, R7
    SHSUB16 R7, R3, R7
    SMLAD R2, R7, R14, R11
    SMUSD R10, R7, R14
    ASR R10, R10, #15
    ASR R2, R2, #15
    PKHBT R7, R10, R2, LSL #16

; Stage 2.
    SHADD16 R2, R8, R0
    SHSUB16 R0, R8, R0

    SHADD16 R3, R9, R1
    SHSUB16 R1, R9, R1
    SSAX R1, R13, R1

    SHADD16 R8, R4, R6
    SHSUB16 R6, R4, R6

    SHADD16 R9, R5, R7
    SHSUB16 R7, R5, R7
    SSAX R7, R13, R7

; Output base. This remains timed because R10 is used as a temporary above.
    MOV R10, #512

; Final butterflies and first 8 output slots.
; Order after first STMIA:
;   R0 real0, R1 imag0, R2 real1, R3 imag1,
;   R4 real2, R5 imag2, R11 real3, R12 imag3
    SHADD16 R4, R0, R1
    SHSUB16 R11, R0, R1
    ASR R5, R4, #16
    ASR R12, R11, #16

    SHADD16 R0, R2, R3
    SHSUB16 R2, R2, R3
    ASR R1, R0, #16
    ASR R3, R2, #16

    STMIA R10!, {R0-R5,R11-R12}

; Final butterflies and last 8 output slots.
    SHADD16 R0, R8, R9
    SHSUB16 R2, R8, R9
    ASR R1, R0, #16
    ASR R3, R2, #16

    SHADD16 R4, R6, R7
    SHSUB16 R11, R6, R7
    ASR R5, R4, #16
    ASR R12, R11, #16

    STMIA R10!, {R0-R5,R11-R12}

DONE:
    B DONE
