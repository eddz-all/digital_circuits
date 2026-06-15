; 8-point DFT/FFT sample program for the first MCU32 interface.
;
; Target ISA:
;   Custom first-version ARM-like MCU, 32-bit registers R0..R15.
;
; Instruction subset used:
;   MOV, ADD, SUB, CMP, LDR, STR, B, BNE, MUL
;
; Teacher sample input layout, 16-bit signed slots, program-view +4 stride:
;   input slots   0..63   DFT matrix real coefficients, Q7, row-major
;   input slots  64..127  DFT matrix imaginary coefficients, Q7, row-major
;   input slots 128..135  signal real samples, Q5
;   input slots 136..143  signal imaginary samples, Q5
;
; Output layout, 16-bit signed slots, program-view +4 stride:
;   output slots 0..7     DFT result real parts, Q12, natural order
;   output slots 8..15    DFT result imaginary parts, Q12, natural order
;
; Computation:
;   For each output k:
;     real[k] = sum_n xr[n] * wr[k,n] - xi[n] * wi[k,n]
;     imag[k] = sum_n xr[n] * wi[k,n] + xi[n] * wr[k,n]
;
; Q5 * Q7 accumulates directly into Q12. No FFT/8 scaling and no
; bit-reversal output are applied.

START:
    MOV R8, #0          ; current DFT real-matrix row pointer
    MOV R9, #256        ; current DFT imag-matrix row pointer
    MOV R12, #2048      ; output real slot 0 address
    MOV R13, #2080      ; output imag slot 8 address
    MOV R14, #8         ; output rows remaining

OUTPUT_LOOP:
    MOV R4, #0          ; real accumulator, Q12
    MOV R5, #0          ; imag accumulator, Q12
    MOV R10, #512       ; signal real slot 128 address
    MOV R11, #544       ; signal imag slot 136 address
    MOV R6, #8          ; columns remaining

MAC_LOOP:
    LDR R0, [R10 + 0]   ; xr[n], Q5
    LDR R1, [R11 + 0]   ; xi[n], Q5
    LDR R2, [R8 + 0]    ; wr[k,n], Q7
    LDR R3, [R9 + 0]    ; wi[k,n], Q7

    MUL R7, R0, R2
    ADD R4, R4, R7
    MUL R7, R1, R3
    SUB R4, R4, R7

    MUL R7, R0, R3
    ADD R5, R5, R7
    MUL R7, R1, R2
    ADD R5, R5, R7

    ADD R8, R8, #4
    ADD R9, R9, #4
    ADD R10, R10, #4
    ADD R11, R11, #4
    SUB R6, R6, #1
    CMP R6, #0
    BNE MAC_LOOP

    STR R4, [R12 + 0]
    STR R5, [R13 + 0]
    ADD R12, R12, #4
    ADD R13, R13, #4
    SUB R14, R14, #1
    CMP R14, #0
    BNE OUTPUT_LOOP

DONE:
    B DONE
