/*
 * 8-point forward FFT, basic scalar ARM-like version.
 *
 * Purpose:
 *   This is the easy-to-build MCU baseline. It avoids ARM DSP/SIMD
 *   instructions such as SHADD16, SMUAD, SMUSD, PKHBT, SXTH, LDM, and STM.
 *
 * Instruction subset after macro expansion:
 *   LDR, STR, MOV, ADD, SUB, RSB, ASR, LSL, BX
 *
 * Numeric format:
 *   Internal data memory stores each real/imag component as one signed
 *   32-bit word. The value itself is still 16-bit Q15 range.
 *
 * Internal scratch layout:
 *   scratch + 0   = x0.real
 *   scratch + 4   = x0.imag
 *   scratch + 8   = x1.real
 *   scratch + 12  = x1.imag
 *   ...
 *   scratch + 56  = x7.real
 *   scratch + 60  = x7.imag
 *
 * Calling convention:
 *   r0 = input pointer,  16 signed 32-bit words: re0, im0, ..., re7, im7
 *   r1 = output pointer, 16 signed 32-bit words
 *   r2 = scratch pointer, at least 64 bytes
 *
 * Transform:
 *   Radix-2 DIF, fully unrolled.
 *   Forward FFT: exp(-j * 2*pi*k/8).
 *   Every butterfly divides by 2, so output = FFT(input) / 8.
 *
 * Output order:
 *   Bit-reversal order:
 *      X0, X4, X2, X6, X1, X5, X3, X7
 *
 * Note:
 *   This file uses assembler macros to keep the source readable. If your
 *   custom instruction ROM builder does not support macros, expand them into
 *   plain instructions first.
 */

    .syntax unified
    .thumb
    .text

/*
 * out = round-toward-negative-infinity(in * 0.70710678) in Q15.
 *
 * 0.70710678 in Q15 = 23170 = 2^14 + 2^12 + 2^11 + 2^9 + 2^7 + 2^1.
 *
 * So:
 *   out = (in * 23170) >> 15
 */
    .macro MUL_INV_SQRT2 out, in, tmp
        lsl     \out, \in, #14
        lsl     \tmp, \in, #12
        add     \out, \out, \tmp
        lsl     \tmp, \in, #11
        add     \out, \out, \tmp
        lsl     \tmp, \in, #9
        add     \out, \out, \tmp
        lsl     \tmp, \in, #7
        add     \out, \out, \tmp
        lsl     \tmp, \in, #1
        add     \out, \out, \tmp
        asr     \out, \out, #15
    .endm

/*
 * Butterfly with twiddle W = 1.
 *
 * A = (A + B) / 2
 * B = (A_old - B_old) / 2
 */
    .macro BF_W0 off_a, off_b
        ldr     r3, [r2, #\off_a]
        ldr     r4, [r2, #(\off_a + 4)]
        ldr     r5, [r2, #\off_b]
        ldr     r6, [r2, #(\off_b + 4)]

        add     r7, r3, r5
        asr     r7, r7, #1
        sub     r8, r3, r5
        asr     r8, r8, #1

        add     r9, r4, r6
        asr     r9, r9, #1
        sub     r10, r4, r6
        asr     r10, r10, #1

        str     r7, [r2, #\off_a]
        str     r9, [r2, #(\off_a + 4)]
        str     r8, [r2, #\off_b]
        str     r10, [r2, #(\off_b + 4)]
    .endm

/*
 * Butterfly with twiddle W = -j.
 *
 * D = (A_old - B_old) / 2
 * D * (-j): real' = D.imag, imag' = -D.real
 */
    .macro BF_NEG_J off_a, off_b
        ldr     r3, [r2, #\off_a]
        ldr     r4, [r2, #(\off_a + 4)]
        ldr     r5, [r2, #\off_b]
        ldr     r6, [r2, #(\off_b + 4)]

        add     r7, r3, r5
        asr     r7, r7, #1
        sub     r8, r3, r5
        asr     r8, r8, #1

        add     r9, r4, r6
        asr     r9, r9, #1
        sub     r10, r4, r6
        asr     r10, r10, #1

        str     r7, [r2, #\off_a]
        str     r9, [r2, #(\off_a + 4)]
        str     r10, [r2, #\off_b]
        rsb     r8, r8, #0
        str     r8, [r2, #(\off_b + 4)]
    .endm

/*
 * Butterfly with twiddle W = 0.7071 - j0.7071.
 *
 * D = (A_old - B_old) / 2
 * real' = C * (D.real + D.imag)
 * imag' = C * (D.imag - D.real)
 */
    .macro BF_W1 off_a, off_b
        ldr     r3, [r2, #\off_a]
        ldr     r4, [r2, #(\off_a + 4)]
        ldr     r5, [r2, #\off_b]
        ldr     r6, [r2, #(\off_b + 4)]

        add     r7, r3, r5
        asr     r7, r7, #1
        sub     r8, r3, r5
        asr     r8, r8, #1

        add     r9, r4, r6
        asr     r9, r9, #1
        sub     r10, r4, r6
        asr     r10, r10, #1

        str     r7, [r2, #\off_a]
        str     r9, [r2, #(\off_a + 4)]

        add     r11, r8, r10
        MUL_INV_SQRT2 r7, r11, r12
        sub     r11, r10, r8
        MUL_INV_SQRT2 r9, r11, r12

        str     r7, [r2, #\off_b]
        str     r9, [r2, #(\off_b + 4)]
    .endm

/*
 * Butterfly with twiddle W = -0.7071 - j0.7071.
 *
 * D = (A_old - B_old) / 2
 * real' = C * (D.imag - D.real)
 * imag' = -C * (D.real + D.imag)
 */
    .macro BF_W3 off_a, off_b
        ldr     r3, [r2, #\off_a]
        ldr     r4, [r2, #(\off_a + 4)]
        ldr     r5, [r2, #\off_b]
        ldr     r6, [r2, #(\off_b + 4)]

        add     r7, r3, r5
        asr     r7, r7, #1
        sub     r8, r3, r5
        asr     r8, r8, #1

        add     r9, r4, r6
        asr     r9, r9, #1
        sub     r10, r4, r6
        asr     r10, r10, #1

        str     r7, [r2, #\off_a]
        str     r9, [r2, #(\off_a + 4)]

        sub     r11, r10, r8
        MUL_INV_SQRT2 r7, r11, r12
        add     r11, r8, r10
        MUL_INV_SQRT2 r9, r11, r12
        rsb     r9, r9, #0

        str     r7, [r2, #\off_b]
        str     r9, [r2, #(\off_b + 4)]
    .endm

    .global fft8_basic_scalar_q15_br
    .type fft8_basic_scalar_q15_br, %function

fft8_basic_scalar_q15_br:
    /*
     * Copy 16 input words into scratch.
     * This is deliberately unrolled to avoid BNE loop overhead.
     */
    ldr     r3, [r0, #0]
    str     r3, [r2, #0]
    ldr     r3, [r0, #4]
    str     r3, [r2, #4]
    ldr     r3, [r0, #8]
    str     r3, [r2, #8]
    ldr     r3, [r0, #12]
    str     r3, [r2, #12]
    ldr     r3, [r0, #16]
    str     r3, [r2, #16]
    ldr     r3, [r0, #20]
    str     r3, [r2, #20]
    ldr     r3, [r0, #24]
    str     r3, [r2, #24]
    ldr     r3, [r0, #28]
    str     r3, [r2, #28]
    ldr     r3, [r0, #32]
    str     r3, [r2, #32]
    ldr     r3, [r0, #36]
    str     r3, [r2, #36]
    ldr     r3, [r0, #40]
    str     r3, [r2, #40]
    ldr     r3, [r0, #44]
    str     r3, [r2, #44]
    ldr     r3, [r0, #48]
    str     r3, [r2, #48]
    ldr     r3, [r0, #52]
    str     r3, [r2, #52]
    ldr     r3, [r0, #56]
    str     r3, [r2, #56]
    ldr     r3, [r0, #60]
    str     r3, [r2, #60]

    /*
     * Stage 1:
     *   (0,4)*W0, (1,5)*W1, (2,6)*W2, (3,7)*W3
     */
    BF_W0       0, 32
    BF_W1       8, 40
    BF_NEG_J   16, 48
    BF_W3      24, 56

    /*
     * Stage 2:
     *   groups (0,1,2,3) and (4,5,6,7)
     */
    BF_W0       0, 16
    BF_NEG_J    8, 24
    BF_W0      32, 48
    BF_NEG_J   40, 56

    /*
     * Stage 3:
     *   final 2-point butterflies.
     */
    BF_W0       0, 8
    BF_W0      16, 24
    BF_W0      32, 40
    BF_W0      48, 56

    /*
     * Store 16 output words in bit-reversal order:
     *   X0, X4, X2, X6, X1, X5, X3, X7
     */
    ldr     r3, [r2, #0]
    str     r3, [r1, #0]
    ldr     r3, [r2, #4]
    str     r3, [r1, #4]
    ldr     r3, [r2, #8]
    str     r3, [r1, #8]
    ldr     r3, [r2, #12]
    str     r3, [r1, #12]
    ldr     r3, [r2, #16]
    str     r3, [r1, #16]
    ldr     r3, [r2, #20]
    str     r3, [r1, #20]
    ldr     r3, [r2, #24]
    str     r3, [r1, #24]
    ldr     r3, [r2, #28]
    str     r3, [r1, #28]
    ldr     r3, [r2, #32]
    str     r3, [r1, #32]
    ldr     r3, [r2, #36]
    str     r3, [r1, #36]
    ldr     r3, [r2, #40]
    str     r3, [r1, #40]
    ldr     r3, [r2, #44]
    str     r3, [r1, #44]
    ldr     r3, [r2, #48]
    str     r3, [r1, #48]
    ldr     r3, [r2, #52]
    str     r3, [r1, #52]
    ldr     r3, [r2, #56]
    str     r3, [r1, #56]
    ldr     r3, [r2, #60]
    str     r3, [r1, #60]

    bx      lr

    .size fft8_basic_scalar_q15_br, . - fft8_basic_scalar_q15_br

