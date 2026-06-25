# Worker Timing Audit

This audit records the safe optimization applied to the four-worker FFT program.

## Current Count

The counted instruction window is expected to be:

```text
mcu_fft_system_tb cnt_cycles 28
cnt_test = 0001C
```

Input loading from `test_ROM[128..143]` and output dumping to `verify_RAM[0..15]`
remain outside the counted instruction window.

The worker path is now explicit:

```text
fetch PC -> 32-bit instruction ROM -> fetch-side decoder
fetch decode register -> execute register -> execute
```

The fetch-side decode registers reduce the instruction-to-operand critical path.
Straight-line code still overlaps fetch, decode and execute after pipeline fill.
`SMUAD` and `SMUSD` use extra internal DSP stages to avoid a two-DSP plus
writeback path in a single clock. Independent back-to-back DSP instructions can
enter a local pair pipeline, and the common following `ASR` can retire with the
second DSP writeback. Safe adjacent `MOV/MOV` and `SADD16/SSUB16` pairs can
also retire together.

## Safe Optimizations

The original twiddle prologue built `-91/-91` with a scalar subtract followed by
`PKHBT`. The current prologue builds packed `+91/+91` first, then uses standard
ARM DSP packed subtract:

```asm
MOV    r0, #0
MOV    r1, #91
PKHBT  r3, r1, r1, LSL #16 ; 0x005B005B
SSUB16 r4, r0, r3          ; 0xFFA5FFA5
```

This removes one counted instruction without adding a custom opcode, hiding a
constant in hardware, or changing `LDR`, `STR`, or `MOV` semantics.

The later timing/count optimizations also stay inside the visible ARM/ARM-DSP
program model:

```text
Local dual issue: retires safe MOV/MOV and SADD16/SSUB16 pairs together.
DSP pair pipeline: overlaps independent SMUAD/SMUSD execution.
ASR overlap: retires the existing ASR instruction with the second DSP writeback.
```

They do not add a new instruction, change the ROM program, or implement a
butterfly-specific accelerator.

## Remaining Bottleneck

The longest counted lane is still worker1/worker3 in stage2:

```asm
LDR
LDR
SMUAD/SMUSD
SMUSD/SMUAD
ASR
PKHBT
SADD16
SSUB16
STR
STR
```

The `SADD16/SSUB16` pair now retires in one counted cycle, but the W1/W3 lane
still contains the two loads, DSP pair, pack, and two stores. Worker0 and
worker2 finish earlier and still contain padding near the end of stage2.
Removing only those padding cycles does not reduce system `cnt`, because the
system waits for all workers to halt.

## Stop Rule

Further optimization should stop if it requires any of the following:

```text
FFT-specific opcode
butterfly-specific opcode
hidden twiddle constant
changed LDR/STR/MOV behavior
changed input/output boundary
changed cnt_start/cnt_stop boundary
```
