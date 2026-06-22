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
0014: EB000002    BL   fft_stage0_kernel
0018: EB000007    BL   fft_stage1_kernel
001C: EB00000C    BL   fft_stage2_kernel
0020: EAFFFFFE    B    halt
```

The first five instructions exercise the baseline ARM-style datapath and decoder.
The three `BL` instructions jump to real function bodies in the same instruction
ROM. Each function starts four workers, waits for the multicycle work to finish,
commits the stage results, and returns with `MOV pc, lr`.

```asm
fft_stage0_kernel:
0024: ED800000    DSP_BFLY_START stage0 lane0
0028: ED820000    DSP_BFLY_START stage0 lane1
002C: ED840000    DSP_BFLY_START stage0 lane2
0030: ED860000    DSP_BFLY_START stage0 lane3
0034: ED600000    DSP_BFLY_WAIT  stage0
0038: E1A0F00E    MOV  pc, lr

fft_stage1_kernel:
003C: ED880000    DSP_BFLY_START stage1 lane0
0040: ED8A0000    DSP_BFLY_START stage1 lane1
0044: ED8C0000    DSP_BFLY_START stage1 lane2
0048: ED8E0000    DSP_BFLY_START stage1 lane3
004C: ED680000    DSP_BFLY_WAIT  stage1
0050: E1A0F00E    MOV  pc, lr

fft_stage2_kernel:
0054: ED900000    DSP_BFLY_START stage2 lane0
0058: ED920000    DSP_BFLY_START stage2 lane1
005C: ED940000    DSP_BFLY_START stage2 lane2
0060: ED960000    DSP_BFLY_START stage2 lane3
0064: ED700000    DSP_BFLY_WAIT  stage2
0068: E1A0F00E    MOV  pc, lr
```

The `DSP_BFLY_WAIT` instruction gives the function its visible multicycle
behavior: it stalls the PC until the four lanes finish. Internally, each lane
follows the same operation shape as DSP instructions such as `SADD16`, `SSUB16`,
`SSAX`, `SMUAD`, `SMUSD`, and `PKHBT`. The W1/W3 multiply path is optimized as
two registered steps: 16x16 multiplications first, then 32-bit sum/subtract.

ROM addresses 27 to 31 contain concrete examples for `LDR`, `STR`, and extra
DSP-extension slots. They are not required for the current FFT run, but they make
the instruction support visible in the source file for report screenshots.
