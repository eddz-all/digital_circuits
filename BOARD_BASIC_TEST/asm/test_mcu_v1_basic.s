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
    B DONE

ZERO:
    MOV R5, #456
    STR R5, [R10 + 12]

DONE:
    B DONE
