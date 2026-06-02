; Basic single-cycle MCU smoke test.
;
; input slot 0 = 1000
; input slot 1 = -500
;
; expected outputs:
;   output slot 0 = 500
;   output slot 1 = 1500
;   output slot 2 = floor(1000 * 23170 / 32768) = 707
;   output slot 3 = 123
;   output slot 4 = 8
;   output slot 5 = 11
;   output slot 6 = address after BL

START:
    MOV R8, #0
    MOV R9, #256
    MOV R10, #512

    LDR R0, [R8 + 0]
    LDR R1, [R8 + 4]

    ADD R2, R0, R1
    STR R2, [R10 + 0]

    SUB R3, R0, R1
    STR R3, [R10 + 4]

    MOV R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #4095
    ADD R12, R12, #2695

    MUL R4, R0, R12
    ASR R4, R4, #15
    STR R4, [R10 + 8]

    CMP R2, #0
    BEQ ZERO

    MOV R5, #123
    STR R5, [R10 + 12]

    MOV R6, #10
    MOV R7, #12
    AND R6, R6, R7
    STR R6, [R10 + 16]
    ORR R7, R6, #3
    STR R7, [R10 + 20]
    BL AFTER_BL
    MOV R5, #999
    STR R5, [R10 + 28]

AFTER_BL:
    STR R14, [R10 + 24]
    B DONE

ZERO:
    MOV R5, #456
    STR R5, [R10 + 12]

DONE:
    B DONE
