# FFT8 V2 Packed DSP 加速版说明

本文档对应：

```text
asm/fft8_v2_packed_dsp.s
asm/fft8_v2_packed_dsp.mem
asm/fft8_v2_packed_dsp.lst
tools/test_fft8_v2_packed_dsp.py
```

完整 V1/V2 Python 与 GHDL 实验数据汇总见：

```text
docs/fft8_experiment_results.md
```

## 1. 目标

V2 是在不破坏 V1 scalar baseline 的前提下新增的加速版本。

当前对比：

```text
V1 scalar:
  286 条指令
  276 条 timed steps
  real / imag 分开用 32-bit 槽位计算

V2 packed DSP:
  120 条指令
  109 条 timed steps
  一个 32-bit 寄存器保存一个 packed complex
```

packed complex 格式：

```text
bits[15:0]   = real, signed 16-bit
bits[31:16]  = imag, signed 16-bit
```

输入/输出外部布局不变，仍然是：

```text
re0, im0, re1, im1, ..., re7, im7
```

## 2. 新增 DSP 指令

扩展类指令格式：

```text
cond[31:28]
op[27:26] = 11
funct[25:21]
reserved[20] = 0
Rn[19:16]
Rd[15:12]
operand2[11:0]
```

新增 funct：

```text
00000 = SHADD16
00001 = SHSUB16
00010 = SMUAD
00011 = SMUSD
00100 = SXTH
00101 = PKHBT
```

语义：

```text
SHADD16  两个 halfword signed 加法后分别算术右移 1
SHSUB16  两个 halfword signed 减法后分别算术右移 1
SMUAD    low*low + high*high，输出 32-bit signed
SMUSD    low*low - high*high，输出 32-bit signed
SXTH     sign_extend(Rn.low16)
PKHBT    {Rm.low16, Rn.low16}
```

## 3. FFT 数据流

V2 使用 radix-2 DIF，输出仍然是 bit-reversal：

```text
X0, X4, X2, X6, X1, X5, X3, X7
```

关键优化：

```text
1. 先把 16 个输入槽位打包成 R0..R7 的 8 个复数。
2. 中间三层蝶形全部在寄存器内完成，不再反复写 WORK RAM。
3. W0 蝶形用 SHADD16 / SHSUB16。
4. W1 / W3 旋转用 SMUAD / SMUSD / ASR / PKHBT。
5. -j 旋转用 SXTH / ASR #16 / SUB / PKHBT。
6. 最后把 packed complex 拆成 real/imag 16 个输出槽位。
```

## 4. 数值边界

V2 packed DSP 是 16-bit lane 固定点加速版本。对中等幅度输入和常见边界样例，它与 V1 scalar fixed model 精确一致。

完整 16-bit 随机输入时，W1 / W3 的中间旋转结果可能超过 signed 16-bit lane 范围。此时 V2 会按 packed halfword 固定点语义截断，而 V1 scalar baseline 会继续保留 32-bit 中间值。因此：

```text
中等幅度随机测试：V2 精确匹配 V1 scalar model
完整 16-bit 随机测试：V2 精确匹配 packed DSP model
```

这符合 V2 的设计目标：作为拓展加速版本展示 packed DSP 指令带来的速度提升；V1 仍保留为最稳妥的全 32-bit scalar reference。

## 5. 验证

运行：

```bash
python3 tools/test_fft8_v2_packed_dsp.py
python3 tools/assemble_mcu_v1.py asm/fft8_v2_packed_dsp.s
```

当前结果：

```text
120 instructions before labels/comments.
119 instructions executed before DONE self-loop.
109 instructions from first input read through last output write.
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
fast target timed_steps <= 130 passed.
```

GHDL core 仿真数据：

```text
tb/mcu_v1_core_tb.vhd
MEM_FILE = asm/fft8_v2_packed_dsp.mem

x0 impulse:
  input:
    x0.real = 32760
    others = 0
  output:
    X0..X7 all real = 4095, imag = 0
  pc_debug = 0x000001DC
  halted_debug = 1
  illegal_debug = 0

x1 impulse:
  input:
    x1.real = 32760
    others = 0
  output slots:
    0:  4095
    1:     0
    2: -4095
    3:     0
    4:     0
    5: -4095
    6:     0
    7:  4095
    8:  2895
    9: -2896
   10: -2896
   11:  2896
   12: -2896
   13: -2896
   14:  2896
   15:  2895
  pc_debug = 0x000001DC
  halted_debug = 1
  illegal_debug = 0
```
