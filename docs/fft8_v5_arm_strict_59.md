# FFT8 V5 ARM-Strict 59

更新时间：2026-06-03

本文记录 V5-arm-strict-59 的实现结果。V5 基于 V4 `78 timed_steps`，只新增 ARM 真实存在的 `SMLAD` 和 `STMIA`，将 FFT8 packed DSP 程序压到 `59 timed_steps`。

## 1. 结果

```text
program: asm/fft8_v5_arm_strict_59.s
mem:     asm/fft8_v5_arm_strict_59.mem
lst:     asm/fft8_v5_arm_strict_59.lst

instructions before labels/comments: 78
instructions executed before DONE self-loop: 77
timed_steps from first input read through last output write: 59
DONE PC: 0x0134
DONE word: 0xE8FFFFFE
```

按 `50 MHz` 估算：

```text
50 MHz / 59 = 84.75 万次/秒
relative to V1 = 276 / 59 = 4.68x
```

## 2. 新增指令

V5 在 `op[27:26] = 11` 扩展类中新增：

```text
EXT_SMLAD = 01010
EXT_STMIA = 01011
ALU_SMLAD = 1111
```

`SMLAD Rd, Rn, Rm, Ra`：

```text
Rd = signed16(Rn.low16) * signed16(Rm.low16)
   + signed16(Rn.high16) * signed16(Rm.high16)
   + Ra
```

`STMIA Rn!, {reglist}`：

```text
按寄存器编号升序把 reglist 写入连续 32-bit 槽位。
写完后 Rn += 4 * popcount(reglist)。
输出区仍只保存每个写入 word 的 low16。
```

V5 仍保持单核、单发射、单周期，一条指令计一个 cnt；没有引入 FFT 硬件旁路、自定义 FFT 指令、fixed-twiddle 指令或 custom complex store。

## 3. 优化点

```text
1. 寄存器重命名，消掉 V4 里 12 条 butterfly 后的 MOV。
2. SMLAD + 32767 bias，把 W3 的 ASR 后取负 exact 压短 1 条。
3. 两条 STMIA R10!, {R0-R5,R11-R12} 替代 8 条 STRD 输出。
```

`SMLAD` 替换保持 exact：

```text
-ASR(x, 15) = ASR(-x + 32767, 15)
```

因此没有采用会改变负数 ASR 舍入的 77-cycle 近似方案。

## 4. 验证

Assembler：

```text
encoded 78 instructions from asm/fft8_v5_arm_strict_59.s
DONE at PC 0x0134, word 0xE8FFFFFE
```

Python checker：

```text
78 instructions before labels/comments.
77 instructions executed before DONE self-loop.
59 instructions from first input read through last output write.
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
V5 target timed_steps <= 59 passed.
```

GHDL `--std=08` 局部验证：

```text
mcu_v1_alu_tb passed @12ns
mcu_v1_decoder_tb passed @37ns
mcu_v1_core_tb passed @18091ns
```
