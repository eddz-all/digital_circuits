/*
 * MCU4 four-worker FFT program, generic-dual-issue cnt22 version.
 *
 * This is a readable assembly listing for the instruction ROM implemented in
 * rtl/mcu4_worker_instr_rom.vhd. It is documentation source, not a required
 * Vivado input file. The explicit VHDL ROM constant tables are the canonical
 * machine-code source used by synthesis.
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
 * Data memory convention:
 *   [r0, #0x40 + 4*n] = work area A word n
 *   [r0, #0x80 + 4*n] = work area B/output word n
 *
 * Visible instruction count is still the ROM PC window. The worker core uses
 * local dual issue for safe MOV/MOV, LDR/LDR, STR/STR, and SADD16/SSUB16
 * pairs. Back-to-back independent SMUAD/SMUSD instructions use the generic DSP
 * pair pipeline, and the dependent ASR can retire with the second DSP
 * writeback. The board counter is 0x16 = 22 cycles.
 */

/* Shared prologue, pc 0..3, all workers. */
pc00:   MOV     r0, #0
pc01:   MOV     r1, #91
pc02:   PKHBT   r3, r1, r1, LSL #16      /* packed +91/+91 */
pc03:   SSUB16  r4, r0, r3               /* packed -91/-91 */

/* Worker 0 */
worker0:
pc04:   LDR     r5, [r0, #0x40]
pc05:   LDR     r6, [r0, #0x44]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, [r0, #0x80]
pc09:   STR     r11, [r0, #0x84]
pc10:   LDR     r5, [r0, #0x80]
pc11:   LDR     r6, [r0, #0x88]
pc12:   SADD16  r10, r5, r6
pc13:   SSUB16  r11, r5, r6
pc14:   STR     r10, [r0, #0x40]
pc15:   STR     r11, [r0, #0x48]
pc16:   NOP
pc17:   LDR     r5, [r0, #0x40]
pc18:   LDR     r6, [r0, #0x50]
pc19:   SADD16  r10, r5, r6
pc20:   SSUB16  r11, r5, r6
pc21:   STR     r10, [r0, #0x80]
pc22:   STR     r11, [r0, #0x90]
pc23:   NOP
pc24:   NOP
pc25:   NOP
pc26:   NOP
pc27:   B       .                       /* encoded as ARM B . completion sentinel */

/* Worker 1 */
worker1:
pc04:   LDR     r5, [r0, #0x48]
pc05:   LDR     r6, [r0, #0x4C]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, [r0, #0x88]
pc09:   STR     r11, [r0, #0x8C]
pc10:   LDR     r5, [r0, #0x84]
pc11:   LDR     r6, [r0, #0x8C]
pc12:   SSAX    r9, r0, r6
pc13:   SADD16  r10, r5, r9
pc14:   SSUB16  r11, r5, r9
pc15:   STR     r10, [r0, #0x44]
pc16:   STR     r11, [r0, #0x4C]
pc17:   LDR     r5, [r0, #0x44]
pc18:   LDR     r6, [r0, #0x54]
pc19:   SMUAD   r7, r6, r3
pc20:   SMUSD   r8, r6, r4
pc21:   ASR     r7, r7, #7
pc22:   PKHBT   r9, r7, r8, LSL #9
pc23:   SADD16  r10, r5, r9
pc24:   SSUB16  r11, r5, r9
pc25:   STR     r10, [r0, #0x84]
pc26:   STR     r11, [r0, #0x94]
pc27:   B       .                       /* encoded as ARM B . completion sentinel */

/* Worker 2 */
worker2:
pc04:   LDR     r5, [r0, #0x50]
pc05:   LDR     r6, [r0, #0x54]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, [r0, #0x90]
pc09:   STR     r11, [r0, #0x94]
pc10:   LDR     r5, [r0, #0x90]
pc11:   LDR     r6, [r0, #0x98]
pc12:   SADD16  r10, r5, r6
pc13:   SSUB16  r11, r5, r6
pc14:   STR     r10, [r0, #0x50]
pc15:   STR     r11, [r0, #0x58]
pc16:   NOP
pc17:   LDR     r5, [r0, #0x48]
pc18:   LDR     r6, [r0, #0x58]
pc19:   SSAX    r9, r0, r6
pc20:   SADD16  r10, r5, r9
pc21:   SSUB16  r11, r5, r9
pc22:   STR     r10, [r0, #0x88]
pc23:   STR     r11, [r0, #0x98]
pc24:   NOP
pc25:   NOP
pc26:   NOP
pc27:   B       .                       /* encoded as ARM B . completion sentinel */

/* Worker 3 */
worker3:
pc04:   LDR     r5, [r0, #0x58]
pc05:   LDR     r6, [r0, #0x5C]
pc06:   SADD16  r10, r5, r6
pc07:   SSUB16  r11, r5, r6
pc08:   STR     r10, [r0, #0x98]
pc09:   STR     r11, [r0, #0x9C]
pc10:   LDR     r5, [r0, #0x94]
pc11:   LDR     r6, [r0, #0x9C]
pc12:   SSAX    r9, r0, r6
pc13:   SADD16  r10, r5, r9
pc14:   SSUB16  r11, r5, r9
pc15:   STR     r10, [r0, #0x54]
pc16:   STR     r11, [r0, #0x5C]
pc17:   LDR     r5, [r0, #0x4C]
pc18:   LDR     r6, [r0, #0x5C]
pc19:   SMUSD   r7, r6, r4
pc20:   SMUAD   r8, r6, r4
pc21:   ASR     r7, r7, #7
pc22:   PKHBT   r9, r7, r8, LSL #9
pc23:   SADD16  r10, r5, r9
pc24:   SSUB16  r11, r5, r9
pc25:   STR     r10, [r0, #0x8C]
pc26:   STR     r11, [r0, #0x9C]
pc27:   B       .                       /* encoded as ARM B . completion sentinel */
