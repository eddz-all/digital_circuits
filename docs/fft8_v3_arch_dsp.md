# FFT8 V3 ARM-Safe Architecture DSP 优化版说明

本文档对应：

```text
asm/fft8_v3_arch_dsp.s
asm/fft8_v3_arch_dsp.mem
asm/fft8_v3_arch_dsp.lst
tools/test_fft8_v3_arch_dsp.py
```

V3 是在 V2 packed DSP 基础上的架构优化版。它不引入 `FFT8`、固定 twiddle 复乘、复数 load/store 等明显 FFT 专用指令；对外展示仍使用 ARM / ARM-DSP 风格汇编，通过 `LDMIA` 和 `STRD` 改善输入输出搬运效率。

## 1. 目标

当前对比：

```text
V1 scalar:
  286 条指令
  276 timed_steps

V2 packed DSP:
  120 条指令
  109 timed_steps

V3 arch DSP:
  98 条指令
  88 timed_steps
```

V3 继续使用 packed complex 格式：

```text
bits[15:0]   = real, signed 16-bit
bits[31:16]  = imag, signed 16-bit
```

输出顺序保持 radix-2 DIF 的 bit-reversal 顺序：

```text
X0, X4, X2, X6, X1, X5, X3, X7
```

## 2. 新增 ARM 风格访存指令

V3 复用当前 `op[27:26] = 11` 扩展类编码，保留 V2 packed DSP funct map。

```text
00110 = LDMIA
00111 = STRD
```

`LDMIA Rn!, {reglist}`：

```text
cond[31:28]
op[27:26]     = 11
funct[25:21]  = 00110
W[20]         = 1
Rn[19:16]     = base register
regmask[15:0] = register list
```

语义：

```text
按寄存器编号升序，从 Rn 指向的连续 32-bit 槽位读入 reglist。
写回 Rn = Rn + 4 * popcount(regmask)。
当前实现不允许 base register 出现在 reglist 中，也不使用 R15。
```

`STRD Rd, Rm, [Rn + imm]`：

```text
cond[31:28]
op[27:26]    = 11
funct[25:21] = 00111
reserved[20] = 0
Rn[19:16]    = base register
Rd[15:12]    = first source register
imm8[11:4]   = byte offset, must be multiple of 4
Rm[3:0]      = second source register
```

语义：

```text
STRD 写 base+imm 和 base+imm+4 两个连续程序视角槽位。
写输出区时，每个槽位仍只保存对应寄存器的 low16，匹配 verify_RAM 16-bit 口径。
```

## 3. V3 数据流

输入阶段：

```text
LDMIA R14!, {R0-R7}
PKHBT 打包 x0..x3
LDMIA R14!, {R4-R11}
PKHBT 打包 x4..x7
```

FFT 主体完全复用 V2 packed DSP 算法：

```text
SHADD16 / SHSUB16
SMUAD / SMUSD
SXTH / ASR / SUB / PKHBT
```

输出阶段：

```text
ASR tmp, Rx, #16
STRD Rx, tmp, [R10 + offset]
```

## 4. Cycle 对比

```text
V2:
  输入打包：16 LDR + 8 PKHBT = 24 cycles
  FFT 主体：61 cycles
  输出拆包：8 STR + 8 ASR + 8 STR = 24 cycles
  总计：109 timed_steps

V3:
  输入打包：2 LDMIA + 8 PKHBT + 1 MOV = 11 cycles
  FFT 主体：61 cycles
  输出拆包：8 ASR + 8 STRD = 16 cycles
  总计：88 timed_steps
```

如果按 `150 MHz` 估算：

```text
V3: 150 MHz / 88 = 170.45 万次/秒
```

## 5. 验证

运行：

```bash
python3 tools/test_fft8_v3_arch_dsp.py
python3 tools/assemble_mcu_v1.py asm/fft8_v3_arch_dsp.s
```

当前结果：

```text
98 instructions before labels/comments.
97 instructions executed before DONE self-loop.
88 instructions from first input read through last output write.
7 edge-case tests passed.
1000 random moderate-amplitude tests passed.
5000 random full-range packed-semantics tests passed.
V3 target timed_steps <= 90 passed.
```

GHDL core test 覆盖：

```text
tb/mcu_v1_core_tb.vhd
MEM_FILE = asm/fft8_v3_arch_dsp.mem

x0 impulse:
  X0..X7 all real = 4095, imag = 0
  pc_debug = 0x00000184
  halted_debug = 1
  illegal_debug = 0

x1 impulse:
  output slots match V1/V2 bit-reversal spectrum
  pc_debug = 0x00000184
  halted_debug = 1
  illegal_debug = 0
```
