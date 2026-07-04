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
 * Data memory convention in this program. All result slots are in the first
 * data window so the board checker can read the self-test as normal data:
 *   r0 = 0
 *   [r0, #0x40] -> data[0] LDR input, initialized to 5
 *   [r0, #0x44] -> data[1] MOV result, expected 7
 *   [r0, #0x48] -> data[2] ADD result, expected 10
 *   [r0, #0x4C] -> data[3] SUB result, expected 7
 *   [r0, #0x50] -> data[4] AND result, expected 2
 *   [r0, #0x54] -> data[5] ORR result, expected 3
 *   [r0, #0x58] -> data[6] LDR result, expected 5
 *   [r0, #0x5C] -> data[7] B/BL/MOV pc,lr result, expected 15
 */

pc00:   .word   0xE3A00000      /* MOV r0, #0 */
pc01:   .word   0xE3A01007      /* MOV r1, #7 */
pc02:   .word   0xE5801044      /* STR r1, [r0, #0x44] ; data[1] = MOV result */
pc03:   .word   0xE3A02003      /* MOV r2, #3 */
pc04:   .word   0xE0813002      /* ADD r3, r1, r2 */
pc05:   .word   0xE5803048      /* STR r3, [r0, #0x48] ; data[2] = ADD result */
pc06:   .word   0xE0434002      /* SUB r4, r3, r2 */
pc07:   .word   0xE580404C      /* STR r4, [r0, #0x4C] ; data[3] = SUB result */
pc08:   .word   0xE0035001      /* AND r5, r3, r1 */
pc09:   .word   0xE5805050      /* STR r5, [r0, #0x50] ; data[4] = AND result */
pc10:   .word   0xE1856002      /* ORR r6, r5, r2 */
pc11:   .word   0xE5806054      /* STR r6, [r0, #0x54] ; data[5] = ORR result */
pc12:   .word   0xE5908040      /* LDR r8, [r0, #0x40] ; data[0] */
pc13:   .word   0xE5808058      /* STR r8, [r0, #0x58] ; data[6] = LDR result */
pc14:   .word   0xE3A0B000      /* MOV r11, #0 ; branch poison accumulator */
pc15:   .word   0xEA000000      /* B pc17 */
pc16:   .word   0xE3A0B063      /* MOV r11, #99 ; skipped poison write */
pc17:   .word   0xEB000002      /* BL pc21 */
pc18:   .word   0xE08AC00B      /* ADD r12, r10, r11 */
pc19:   .word   0xE580C05C      /* STR r12, [r0, #0x5C] ; data[7] = control-flow result */
pc20:   .word   0xEAFFFFFE      /* B . completion sentinel */
pc21:   .word   0xE3A0A00F      /* MOV r10, #15 */
pc22:   .word   0xE1A0F00E      /* MOV pc, lr */
