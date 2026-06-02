/*
 * 8-point forward FFT, single-core single-issue baseline.
 *
 * Target ISA subset:
 *   ARMv7E-M / Thumb-2 DSP instructions.
 *
 * Numeric format:
 *   One complex Q15 sample is packed in one 32-bit word:
 *
 *       bits[15:0]  = real, signed Q15
 *       bits[31:16] = imag, signed Q15
 *
 * Transform:
 *   Forward FFT using W_N = exp(-j * 2*pi/N).
 *   Radix-2 DIF, fully unrolled for N = 8.
 *   Each butterfly uses halving add/sub, so output = FFT(input) / 8.
 *
 * Output order:
 *   Bit-reversal order, which is the natural output order of DIF:
 *
 *       X0, X4, X2, X6, X1, X5, X3, X7
 *
 * Calling convention for this kernel:
 *   r0 = pointer to 8 packed input complex words
 *   r1 = pointer to output buffer for 8 packed complex words
 *
 * Fast-path hardware notes:
 *   - Implement SHADD16/SHSUB16 as 1-cycle operations.
 *   - Implement SMUAD/SMUSD as pipelined DSP operations.
 *   - If LDM/STM are supported by the soft MCU, map them to the fastest
 *     available internal-memory path.
 */

    .syntax unified
    .thumb
    .text

    .equ INV_SQRT2_Q15, 0x5A82

/*
 * rd = rn * (0.70710678 - j0.70710678)
 *
 * rn = {imag, real}
 * rd = {imag', real'}
 *
 * real' = C * (real + imag)
 * imag' = C * (imag - real)
 */
    .macro CMUL_W1 rd, rn, tmp_sum, tmp_diff
        smuad   \tmp_sum,  \rn, r12
        smusd   \tmp_diff, \rn, r12
        rsb     \tmp_diff, \tmp_diff, #0
        asr     \tmp_sum,  \tmp_sum, #15
        asr     \tmp_diff, \tmp_diff, #15
        pkhbt   \rd, \tmp_sum, \tmp_diff, lsl #16
    .endm

/*
 * rd = rn * (-0.70710678 - j0.70710678)
 *
 * real' = C * (imag - real)
 * imag' = -C * (real + imag)
 */
    .macro CMUL_W3 rd, rn, tmp_sum, tmp_diff
        smuad   \tmp_sum,  \rn, r12
        smusd   \tmp_diff, \rn, r12
        rsb     \tmp_diff, \tmp_diff, #0
        rsb     \tmp_sum,  \tmp_sum, #0
        asr     \tmp_diff, \tmp_diff, #15
        asr     \tmp_sum,  \tmp_sum, #15
        pkhbt   \rd, \tmp_diff, \tmp_sum, lsl #16
    .endm

/*
 * rd = rn * (-j)
 *
 * real' = imag
 * imag' = -real
 */
    .macro CMUL_NEG_J rd, rn, tmp_real, tmp_imag
        sxth    \tmp_real, \rn
        asr     \tmp_imag, \rn, #16
        rsb     \tmp_real, \tmp_real, #0
        pkhbt   \rd, \tmp_imag, \tmp_real, lsl #16
    .endm

    .global fft8_dif_q15_packed_br
    .type fft8_dif_q15_packed_br, %function

fft8_dif_q15_packed_br:
    mov     r10, r0
    mov     r11, r1

    movw    r12, #INV_SQRT2_Q15
    movt    r12, #INV_SQRT2_Q15

    /*
     * Load x0..x7.
     *
     * After this:
     *   r0=x0, r1=x1, r2=x2, r3=x3
     *   r4=x4, r5=x5, r6=x6, r7=x7
     */
    ldmia.w r10!, {r0-r7}

    /*
     * Stage 1, N=8 DIF butterflies.
     *
     * After this:
     *   r0=a0, r1=a1, r2=a2, r3=a3
     *   r4=b0, r5=b1, r6=b2, r7=b3
     */
    shadd16 r8, r0, r4
    shsub16 r4, r0, r4
    mov     r0, r8

    shadd16 r8, r1, r5
    shsub16 r5, r1, r5
    mov     r1, r8
    CMUL_W1 r5, r5, r8, r9

    shadd16 r8, r2, r6
    shsub16 r6, r2, r6
    mov     r2, r8
    CMUL_NEG_J r6, r6, r8, r9

    shadd16 r8, r3, r7
    shsub16 r7, r3, r7
    mov     r3, r8
    CMUL_W3 r7, r7, r8, r9

    /*
     * Stage 2, two 4-point DIF groups.
     *
     * After this:
     *   r0=c0, r1=c1, r2=d0, r3=d1
     *   r4=e0, r5=e1, r6=f0, r7=f1
     */
    shadd16 r8, r0, r2
    shsub16 r2, r0, r2
    mov     r0, r8

    shadd16 r8, r1, r3
    shsub16 r3, r1, r3
    mov     r1, r8
    CMUL_NEG_J r3, r3, r8, r9

    shadd16 r8, r4, r6
    shsub16 r6, r4, r6
    mov     r4, r8

    shadd16 r8, r5, r7
    shsub16 r7, r5, r7
    mov     r5, r8
    CMUL_NEG_J r7, r7, r8, r9

    /*
     * Stage 3, four 2-point DIF butterflies.
     *
     * Final registers:
     *   r0=X0, r1=X4, r2=X2, r3=X6
     *   r4=X1, r5=X5, r6=X3, r7=X7
     *
     * All outputs are scaled by 1/8.
     */
    shadd16 r8, r0, r1
    shsub16 r1, r0, r1
    mov     r0, r8

    shadd16 r8, r2, r3
    shsub16 r3, r2, r3
    mov     r2, r8

    shadd16 r8, r4, r5
    shsub16 r5, r4, r5
    mov     r4, r8

    shadd16 r8, r6, r7
    shsub16 r7, r6, r7
    mov     r6, r8

    /*
     * Store in bit-reversal order:
     *   X0, X4, X2, X6, X1, X5, X3, X7
     */
    stmia.w r11!, {r0-r7}

    bx      lr

    .size fft8_dif_q15_packed_br, . - fft8_dif_q15_packed_br

