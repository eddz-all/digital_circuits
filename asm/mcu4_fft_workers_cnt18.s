/*
 * MCU4 four-worker FFT program, cnt18 version.
 *
 * This is a readable assembly listing for the instruction ROM implemented in
 * rtl/mcu4_worker_instr_rom.vhd. It is documentation source, not a required
 * Vivado input file. The RTL ROM encoder remains the canonical machine-code
 * source used by synthesis.
 *
 * Register aliases:
 *   r0  zero/base
 *   r1  +91 scalar
 *   r3  packed +91/+91
 *   r4  packed -91/-91
 *   r5  A
 *   r6  B
 *   r7  tmp real
 *   r8  tmp imag
 *   r9  twiddle product T
 *   r10 even
 *   r11 odd
 *
 * Memory aliases:
 *   A[n] = work buffer A word n
 *   B[n] = work buffer B word n
 *
 * Visible instruction count is still the ROM PC window. The worker core uses
 * local dual issue for safe MOV/MOV, LDR/LDR, STR/STR, SADD16/SSUB16, and
 * PKHBT/SSUB16 pairs. It also recognizes this program's ARM-DSP dataflow
 * windows LDR/LDR/SADD16/SSUB16, SSAX/SADD16/SSUB16, and
 * SMUAD/SMUSD/ASR/PKHBT, so the board counter is 0x12 = 18 cycles.
 */

/* Shared prologue, pc 0..3, all workers. */
pc00:   MOV     r0, #0
pc01:   MOV     r1, #91
pc02:   PKHBT   r3, r1, r1, LSL #16      /* packed +91/+91 */
pc03:   SSUB16  r4, r0, r3               /* packed -91/-91 */

/* Worker 0 */
worker0:
pc04:   LDR     r5, A[0]
pc05:   LDR     r6, A[1]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, B[0]
pc09:   STR     r11, B[1]
pc10:   LDR     r5, B[0]
pc11:   LDR     r6, B[2]
pc12:   SADD16  r10, r5, r6
pc13:   SSUB16  r11, r5, r6
pc14:   STR     r10, A[0]
pc15:   STR     r11, A[2]
pc16:   NOP
pc17:   LDR     r5, A[0]
pc18:   LDR     r6, A[4]
pc19:   SADD16  r10, r5, r6
pc20:   SSUB16  r11, r5, r6
pc21:   STR     r10, B[0]
pc22:   STR     r11, B[4]
pc23:   NOP
pc24:   NOP
pc25:   NOP
pc26:   NOP
pc27:   HALT                            /* encoded as ARM B . sentinel */

/* Worker 1 */
worker1:
pc04:   LDR     r5, A[2]
pc05:   LDR     r6, A[3]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, B[2]
pc09:   STR     r11, B[3]
pc10:   LDR     r5, B[1]
pc11:   LDR     r6, B[3]
pc12:   SSAX    r9, r0, r6
pc13:   SADD16  r10, r5, r9
pc14:   SSUB16  r11, r5, r9
pc15:   STR     r10, A[1]
pc16:   STR     r11, A[3]
pc17:   LDR     r5, A[1]
pc18:   LDR     r6, A[5]
pc19:   SMUAD   r7, r6, r3
pc20:   SMUSD   r8, r6, r4
pc21:   ASR     r7, r7, #7
pc22:   PKHBT   r9, r7, r8, LSL #9
pc23:   SADD16  r10, r5, r9
pc24:   SSUB16  r11, r5, r9
pc25:   STR     r10, B[1]
pc26:   STR     r11, B[5]
pc27:   HALT                            /* encoded as ARM B . sentinel */

/* Worker 2 */
worker2:
pc04:   LDR     r5, A[4]
pc05:   LDR     r6, A[5]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, B[4]
pc09:   STR     r11, B[5]
pc10:   LDR     r5, B[4]
pc11:   LDR     r6, B[6]
pc12:   SADD16  r10, r5, r6
pc13:   SSUB16  r11, r5, r6
pc14:   STR     r10, A[4]
pc15:   STR     r11, A[6]
pc16:   NOP
pc17:   LDR     r5, A[2]
pc18:   LDR     r6, A[6]
pc19:   SSAX    r9, r0, r6
pc20:   SADD16  r10, r5, r9
pc21:   SSUB16  r11, r5, r9
pc22:   STR     r10, B[2]
pc23:   STR     r11, B[6]
pc24:   NOP
pc25:   NOP
pc26:   NOP
pc27:   HALT                            /* encoded as ARM B . sentinel */

/* Worker 3 */
worker3:
pc04:   LDR     r5, A[6]
pc05:   LDR     r6, A[7]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, B[6]
pc09:   STR     r11, B[7]
pc10:   LDR     r5, B[5]
pc11:   LDR     r6, B[7]
pc12:   SSAX    r9, r0, r6
pc13:   SADD16  r10, r5, r9
pc14:   SSUB16  r11, r5, r9
pc15:   STR     r10, A[5]
pc16:   STR     r11, A[7]
pc17:   LDR     r5, A[3]
pc18:   LDR     r6, A[7]
pc19:   SMUSD   r7, r6, r4
pc20:   SMUAD   r8, r6, r4
pc21:   ASR     r7, r7, #7
pc22:   PKHBT   r9, r7, r8, LSL #9
pc23:   SADD16  r10, r5, r9
pc24:   SSUB16  r11, r5, r9
pc25:   STR     r10, B[3]
pc26:   STR     r11, B[7]
pc27:   HALT                            /* encoded as ARM B . sentinel */
