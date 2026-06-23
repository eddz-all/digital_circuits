# Worker Timing Audit

This audit records the safe optimization applied to the four-worker FFT program.

## Current Count

The counted instruction window is expected to be:

```text
mcu_fft_system_tb cnt_cycles 34
cnt_test = 00022
```

Input loading from `test_ROM[128..143]` and output dumping to `verify_RAM[0..15]`
remain outside the counted instruction window.

The worker path is now explicit:

```text
fetch PC -> 32-bit instruction ROM -> instruction register
current instruction -> decoder -> decode register -> execute
```

The instruction and decode registers break the previous PC-to-execute and
instruction-to-execute critical paths. Straight-line code still overlaps fetch,
decode and execute after pipeline fill. `SMUAD` and `SMUSD` then use extra
internal DSP stages to avoid a two-DSP plus writeback path in a single clock.

## Safe Optimization

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

## Remaining Bottleneck

The longest path is still worker1/worker3 in stage2:

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

Worker0 and worker2 finish earlier and still contain padding near the end of
stage2. Removing only those padding cycles does not reduce system `cnt`, because
the system waits for all workers to halt.

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
