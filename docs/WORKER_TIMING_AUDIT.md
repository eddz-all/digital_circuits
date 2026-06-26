# Worker Timing Audit

This audit records the safe optimization applied to the four-worker FFT program.

## Current Count

The counted instruction window is expected to be:

```text
mcu_fft_system_tb cnt_cycles 18
cnt_test = 00012
```

Input loading from `test_ROM[128..143]` and output dumping to `verify_RAM[0..15]`
remain outside the counted instruction window.

The worker path is now explicit:

```text
fetch PC -> 32-bit instruction ROM -> fetch-side decoder
fetch decode register -> execute register -> execute
```

The fetch-side decode registers reduce the instruction-to-operand critical path.
They also stage the decode register-file operands (`rn`, `rm`, and store `rd`)
before execute, so execute no longer has to combine instruction control, a
register-file read mux, and operand forwarding in the same cycle.
Straight-line code still overlaps fetch, decode and execute after pipeline fill.
`SMUAD` and `SMUSD` use extra internal DSP stages to avoid a two-DSP plus
writeback path in a single clock. Independent back-to-back DSP instructions can
enter a local pair pipeline. Safe adjacent `MOV/MOV`, `LDR/LDR`, `STR/STR`,
`SADD16/SSUB16`, and `PKHBT/SSUB16` pairs can also retire together. The current
FFT program also uses local dataflow fusion for `LDR/LDR/SADD16/SSUB16`,
`SSAX/SADD16/SSUB16`, and `SMUAD/SMUSD/ASR/PKHBT` windows.
Those FFT fusion windows are selected from the fixed ROM PC schedule instead of
rechecking long opcode/register match expressions in the execute cycle.
The FFT ROM also emits predecoded control fields directly from the fixed PC
schedule; the 32-bit ARM instruction word is still exposed, while the selftest
program keeps using the generic instruction decoder.
The paired `STR/STR` path stages the second store source operand in the decode
register, cutting the direct register-file-to-second-buffer-write-data path.
Fetch-side operand reads use a dedicated `regs_fetch` replica, separate from the
decode, execute, and store register-file replicas, so fetch/pair direct paths no
longer compete for the same physical read mux as decode-stage operand staging.
The shared work buffers are also replicated per worker for reads; writes update
all replicas, while each worker reads its local copy. This spends storage
resources to reduce global buffer read fanout and cross-worker routing.
Common opcode classes are predecoded into registered `dec_*` and `exec_*` flags,
so buffer controls, DSP pairing, and halt handling do not repeatedly compare the
full opcode enum in high-fanout execute paths.
Dual-issue eligibility is also staged as a pair-kind register, so `S_RUN` no
longer has to recompute opcode, register, and buffer-address match conditions
before selecting the paired retire path.
For the DSP pair tail, the overlapped `ASR` result is precomputed in
`S_DSP_PAIR_WB_ACC` and staged for use in `S_DSP_PAIR_WB`.

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
Local dual issue: retires safe MOV/MOV, LDR/LDR, STR/STR, SADD16/SSUB16, and PKHBT/SSUB16 pairs together.
W0 dataflow fusion: retires the current LDR/LDR/SADD16/SSUB16 window together.
W2 dataflow fusion: retires the current SSAX/SADD16/SSUB16 window together.
DSP pair pipeline: overlaps independent SMUAD/SMUSD execution.
DSP tail fusion: retires the existing ASR and PKHBT tail with the DSP pair writeback.
ASR result staging: precomputes the overlapped ASR result one DSP tail state earlier.
Store operand staging: drives the paired STR second write port from a decode-stage register.
Pair eligibility staging: drives paired retire control from a prequalified pair-kind register.
PC-scheduled FFT fusion: selects the known FFT windows from the ROM PC to reduce execute-cycle compare logic.
Synthesis freedom: internal timing signals are not forced with keep/dont_touch, allowing Vivado to replicate and place them for Fmax.
FFT ROM predecode: emits fixed-program decode fields directly from PC instead of redecoding the 32-bit word in every fetch window.
Decode operand staging: pre-reads rn/rm/rd operands into decode-stage registers before execute to cut route-heavy instruction/control-to-execute operand paths.
Fetch register-file replica: spends flip-flops to split fetch/pair read fanout from decode/execute/store register reads.
Worker-local buffer replicas: spends storage to split shared A/B buffer read fanout across the four workers.
Control class predecode: carries registered opcode class flags through decode/execute instead of re-decoding common control cases on every high-fanout path.
```

They do not add a new instruction, change the ROM program, or implement a
butterfly-specific accelerator.

## Technique Mapping

The design already uses the techniques that fit this fixed FFT workload:

```text
Deep pipelining: fetch/decode/execute operand staging, DSP internal stages, and staged ASR/DSP tail.
Superscalar: safe local dual-issue and fixed FFT dataflow windows retire multiple ARM/ARM-DSP instructions together.
SIMD: ARM DSP packed operations such as SADD16, SSUB16, SSAX, SMUAD, and SMUSD operate on packed lanes.
Multiprocessors: four worker cores split the FFT lanes.
Resource replication: register-file and buffer replicas reduce fanout/routing pressure.
```

The following techniques are intentionally not used in the current RTL because
they add wide control machinery without helping this mostly straight-line fixed
program:

```text
Branch prediction: there are no unpredictable hot branches in the FFT kernel.
Out-of-order execution: dependency tracking, wakeup/select, and reorder state would be larger and slower than the fixed schedule.
Register renaming: the hand-scheduled FFT register use is static; dynamic rename tables would add control-path fanout.
Multithreading: the four workers already expose coarse parallelism, and thread scheduling would add control overhead.
```

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

The W0-style `LDR/LDR/SADD16/SSUB16` window now retires as one local dataflow
window, and the W1/W3 DSP tail fuses through `PKHBT`. The remaining counted
pressure is the multi-cycle DSP pair itself in worker1/worker3. Worker0 and
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
