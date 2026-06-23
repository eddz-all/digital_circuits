# Assembly Listing

Concrete instruction words are stored in:

```text
rtl/mcu4_instr_rom.vhd
```

Visible program:

```asm
0000: E3A00000    MOV  r0, #0
0004: E2801001    ADD  r1, r0, #1
0008: E0414001    SUB  r4, r1, r1
000C: E201200F    AND  r2, r1, #15
0010: E1823000    ORR  r3, r2, r0
0014: EB000000    BL   fft_kernel
0018: EAFFFFFE    B    halt
```

The first five instructions exercise the baseline ARM-style datapath and
decoder. The `BL` instruction jumps to a real function body in the same
instruction ROM. The function controls the four workers through standard
ARM-style `STR`, `LDR`, `CMP`, `BNE`, and `MOV pc, lr` instructions.

```asm
fft_kernel:
001C: E5800000    STR  r0, [r0, #0]     ; start stage0
0020: E5905004    LDR  r5, [r0, #4]     ; done mask
0024: E355000F    CMP  r5, #15
0028: 1AFFFFFC    BNE  stage0_wait
002C: E5800010    STR  r0, [r0, #16]    ; commit stage0

0030: E5800008    STR  r0, [r0, #8]     ; start stage1
0034: E5905004    LDR  r5, [r0, #4]
0038: E355000F    CMP  r5, #15
003C: 1AFFFFFC    BNE  stage1_wait
0040: E5800014    STR  r0, [r0, #20]    ; commit stage1

0044: E580000C    STR  r0, [r0, #12]    ; start stage2
0048: E5905004    LDR  r5, [r0, #4]
004C: E355000F    CMP  r5, #15
0050: 1AFFFFFC    BNE  stage2_wait
0054: E5800018    STR  r0, [r0, #24]    ; commit stage2
0058: E1A0F00E    MOV  pc, lr
```

The visible multicycle behavior now comes from the ARM polling loop:
`LDR` reads a done mask, `CMP` compares it with `15`, and `BNE` repeats until all
four lanes finish. `r0` remains zero throughout the program, so it is used as
both the MMIO base address and dummy write data. The low address range controls
the worker:

```text
[r0, #0]   start stage0
[r0, #4]   read done mask
[r0, #8]   start stage1
[r0, #12]  start stage2
[r0, #16]  commit stage0
[r0, #20]  commit stage1
[r0, #24]  commit stage2
```

The FFT data memory is a multi-port work-memory register array. It is also
single-port accessible by normal ARM `LDR/STR`:

```text
[r0, #64]..[r0, #92]    buf_a[0..7]
[r0, #128]..[r0, #156]  buf_b[0..7]
```

Concrete examples are kept in the ROM after the executed program:

```asm
005C: E5906040    LDR  r6, [r0, #64]     ; read buf_a[0]
0060: E5806080    STR  r6, [r0, #128]    ; write buf_b[0]
```

Internally, each lane follows the same operation shape as DSP instructions such
as `SADD16`, `SSUB16`, `SSAX`, `SMUAD`, `SMUSD`, and `PKHBT`. The W1/W3 multiply
path now uses four parallel registered 16x16 products, then a sum/subtract cycle
and a pack cycle. The MCU explicitly commits each stage into the internal work
buffer with a visible ARM `STR` after the done mask reaches `1111`.

No custom opcode is used by the visible program. `LDR/STR` access both the
memory-mapped worker control registers and the same `buf_a/buf_b` work memory
used by the four lanes.
