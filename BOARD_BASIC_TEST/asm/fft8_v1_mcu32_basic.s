; 8-point radix-2 packed FFT program for the first MCU32 interface.
;
; Target ISA:
;   Custom first-version ARM-like MCU, 32-bit registers R0..R15.
;
; Packed complex format:
;   low16 = real, high16 = imag, both Q12 during the butterfly stages.
;
; DSP subset used:
;   PKHBT Rd, Rn, Rm, LSL #16
;   SADD16 Rd, Rn, Rm
;   SSUB16 Rd, Rn, Rm
;   SSAX Rd, Rn, Rm
;   SMUAD Rd, Rn, Rm
;   SMUSD Rd, Rn, Rm
;   STMIA Rn!, {register list}
;
; Runtime input reads only teacher signal slots 128..143. The bit-reversed
; load order makes the radix-2 DIT stages produce natural-order outputs.

START:
    MOV R8, #0
    MOV R9, #128
    MOV R10, #91
    SUB R11, R8, R10
    PKHBT R12, R10, R10, LSL #16
    PKHBT R13, R11, R11, LSL #16

; Load x0, x4, x2, x6, x1, x5, x3, x7 as packed Q12 complex values.
    LDR R0, [R8 + 512]
    MUL R0, R0, R9
    LDR R14, [R8 + 544]
    MUL R14, R14, R9
    PKHBT R0, R0, R14, LSL #16

    LDR R1, [R8 + 528]
    MUL R1, R1, R9
    LDR R14, [R8 + 560]
    MUL R14, R14, R9
    PKHBT R1, R1, R14, LSL #16

    LDR R2, [R8 + 520]
    MUL R2, R2, R9
    LDR R14, [R8 + 552]
    MUL R14, R14, R9
    PKHBT R2, R2, R14, LSL #16

    LDR R3, [R8 + 536]
    MUL R3, R3, R9
    LDR R14, [R8 + 568]
    MUL R14, R14, R9
    PKHBT R3, R3, R14, LSL #16

    LDR R4, [R8 + 516]
    MUL R4, R4, R9
    LDR R14, [R8 + 548]
    MUL R14, R14, R9
    PKHBT R4, R4, R14, LSL #16

    LDR R5, [R8 + 532]
    MUL R5, R5, R9
    LDR R14, [R8 + 564]
    MUL R14, R14, R9
    PKHBT R5, R5, R14, LSL #16

    LDR R6, [R8 + 524]
    MUL R6, R6, R9
    LDR R14, [R8 + 556]
    MUL R14, R14, R9
    PKHBT R6, R6, R14, LSL #16

    LDR R7, [R8 + 540]
    MUL R7, R7, R9
    LDR R14, [R8 + 572]
    MUL R14, R14, R9
    PKHBT R7, R7, R14, LSL #16

; Stage 1.
    SSUB16 R14, R0, R1
    SADD16 R0, R0, R1
    MOV R1, R14

    SSUB16 R14, R2, R3
    SADD16 R2, R2, R3
    MOV R3, R14

    SSUB16 R14, R4, R5
    SADD16 R4, R4, R5
    MOV R5, R14

    SSUB16 R14, R6, R7
    SADD16 R6, R6, R7
    MOV R7, R14

; Stage 2.
    SSUB16 R14, R0, R2
    SADD16 R0, R0, R2
    MOV R2, R14

    SSAX R3, R8, R3
    SSUB16 R14, R1, R3
    SADD16 R1, R1, R3
    MOV R3, R14

    SSUB16 R14, R4, R6
    SADD16 R4, R4, R6
    MOV R6, R14

    SSAX R7, R8, R7
    SSUB16 R14, R5, R7
    SADD16 R5, R5, R7
    MOV R7, R14

; Stage 3.
    SSUB16 R14, R0, R4
    SADD16 R0, R0, R4
    MOV R4, R14

    SMUAD R14, R5, R12
    SMUSD R15, R5, R13
    ASR R14, R14, #7
    ASR R15, R15, #7
    PKHBT R5, R14, R15, LSL #16
    SSUB16 R14, R1, R5
    SADD16 R1, R1, R5
    MOV R5, R14

    SSAX R6, R8, R6
    SSUB16 R14, R2, R6
    SADD16 R2, R2, R6
    MOV R6, R14

    SMUSD R14, R7, R13
    SMUAD R15, R7, R13
    ASR R14, R14, #7
    ASR R15, R15, #7
    PKHBT R7, R14, R15, LSL #16
    SSUB16 R14, R3, R7
    SADD16 R3, R3, R7
    MOV R7, R14

; Store real0..real7, then imag0..imag7.
    MOV R10, #2048
    STMIA R10!, {R0-R7}
    ASR R0, R0, #16
    ASR R1, R1, #16
    ASR R2, R2, #16
    ASR R3, R3, #16
    ASR R4, R4, #16
    ASR R5, R5, #16
    ASR R6, R6, #16
    ASR R7, R7, #16
    STMIA R10!, {R0-R7}

DONE:
    B DONE
