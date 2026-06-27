/*
 * MCU4 basic instruction/PPT test program.
 *
 * Recommended mode:
 *   PROGRAM_ID   = 1
 *   ACTIVE_CORES = 1
 *
 * The canonical machine code is SELFTEST_ROM in
 * rtl/mcu4_worker_instr_rom.vhd. This file is the readable listing.
 */

pc00:   .word   0xE3A00000      /* MOV r0, #0 */
pc01:   .word   0xE3A01007      /* MOV r1, #7 */
pc02:   .word   0xE3A02003      /* MOV r2, #3 */
pc03:   .word   0xE0813002      /* ADD r3, r1, r2 */
pc04:   .word   0xE0434002      /* SUB r4, r3, r2 */
pc05:   .word   0xE0035001      /* AND r5, r3, r1 */
pc06:   .word   0xE1856002      /* ORR r6, r5, r2 */
pc07:   .word   0xE1A07006      /* MOV r7, r6 */
pc08:   .word   0xE5908040      /* LDR r8, [buf_a+0] */
pc09:   .word   0xE0889007      /* ADD r9, r8, r7 */
pc10:   .word   0xE5809080      /* STR r9, [buf_b+0] */
pc11:   .word   0xEA000000      /* B pc13 */
pc12:   .word   0xE5801084      /* STR r1, [buf_b+1] ; skipped */
pc13:   .word   0xEB000002      /* BL pc17 */
pc14:   .word   0xE5801084      /* STR r1, [buf_b+1] */
pc15:   .word   0xE580A088      /* STR r10, [buf_b+2] */
pc16:   .word   0xEAFFFFFE      /* HALT sentinel */
pc17:   .word   0xE089A004      /* ADD r10, r9, r4 */
pc18:   .word   0xE1A0F00E      /* MOV pc, lr */
