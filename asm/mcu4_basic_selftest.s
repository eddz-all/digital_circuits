/*
 * MCU4 basic instruction/PPT test program.
 *
 * Recommended mode:
 *   PROGRAM_ID   = 1
 *   ACTIVE_CORES = 1
 *
 * The canonical machine code is SELFTEST_ROM in
 * rtl/mcu4_worker_instr_rom.vhd. This file is the readable listing.
 *
 * Data memory convention in this program:
 *   r0 = 0
 *   [r0, #0x40] -> data[0] input
 *   [r0, #0x44] -> data[1] result
 *   [r0, #0x48] -> data[2] result
 *   [r0, #0x4C] -> data[3] result
 *   [r0, #0x50] -> data[4] branch poison slot, should stay zero
 */

pc00:   .word   0xE3A00000      /* MOV r0, #0 */
pc01:   .word   0xE3A01007      /* MOV r1, #7 */
pc02:   .word   0xE3A02003      /* MOV r2, #3 */
pc03:   .word   0xE0813002      /* ADD r3, r1, r2 */
pc04:   .word   0xE0434002      /* SUB r4, r3, r2 */
pc05:   .word   0xE0035001      /* AND r5, r3, r1 */
pc06:   .word   0xE1856002      /* ORR r6, r5, r2 */
pc07:   .word   0xE1A07006      /* MOV r7, r6 */
pc08:   .word   0xE5908040      /* LDR r8, [r0, #0x40] ; data[0] */
pc09:   .word   0xE0889007      /* ADD r9, r8, r7 */
pc10:   .word   0xE5809044      /* STR r9, [r0, #0x44] ; data[1] */
pc11:   .word   0xEA000000      /* B pc13 */
pc12:   .word   0xE5802050      /* STR r2, [r0, #0x50] ; data[4], skipped poison */
pc13:   .word   0xEB000002      /* BL pc17 */
pc14:   .word   0xE5801048      /* STR r1, [r0, #0x48] ; data[2] */
pc15:   .word   0xE580A04C      /* STR r10, [r0, #0x4C] ; data[3] */
pc16:   .word   0xEAFFFFFE      /* HALT sentinel */
pc17:   .word   0xE089A004      /* ADD r10, r9, r4 */
pc18:   .word   0xE1A0F00E      /* MOV pc, lr */
