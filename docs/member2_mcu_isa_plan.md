# 成员 2 第一版 MCU 指令集与接口方案

本文档按 2026-06-02 最新两份要求整理：

```text
/Users/eddz/Library/Containers/com.tencent.qq/Data/Downloads/第一版MCU指令格式说明.md
/Users/eddz/Library/Containers/com.tencent.qq/Data/Downloads/第一版MCU对成员A接口说明.md
```

用途：

```text
1. 成员 B 实现 decoder / controller / extend / datapath
2. 成员 A 编写 8 点 FFT 汇编并翻译成机器码
3. 后续把机器码写入 instr_rom
```

第一版目标不是完整 ARM，而是一个 ARM-like 裁剪版 MCU：32-bit 定长指令、保留 cond 条件字段、保留数据处理/访存/分支三大类。当前 GHDL baseline 已覆盖 PPT 最低指令集所需的 `ADD / SUB / AND / ORR / MOV / LDR / STR / B / BL`，并额外支持 FFT 第一版需要的 `CMP / BEQ / BNE / MUL / ASR`。DSP 加速分支还新增 `op=11` 扩展类 packed 指令，用于 V2 FFT 加速；V3 继续在该扩展类中加入 ARM 风格 `LDMIA/STRD`，用于架构层面的输入输出搬运优化；V4 再加入 ARM SIMD/DSP 风格 `SSAX/SSUB16`，用于 exact cycle 优化。

## 1. 总体约定

```text
指令宽度：32-bit
地址宽度：32-bit
内部通用寄存器数量：16
内部通用寄存器宽度：32-bit
内部计算宽度：32-bit
寻址方式：统一字节寻址
顺序执行默认：PC = PC + 4
```

外部输入/输出仍符合课程要求：

```text
外部输入 test_ROM：16-bit signed
外部输出 verify_RAM：16-bit signed
```

但成员 A 写程序时，寄存器和地址槽位统一按 32-bit signed 理解：

```text
外部世界：16-bit
MCU 程序视角：32-bit 槽位
```

## 2. 地址空间

最新第一版程序统一使用：

```text
INPUT_BASE   = 0x00000000
WORK_BASE    = 0x00000100
OUTPUT_BASE  = 0x00000200
```

含义：

```text
INPUT_BASE   输入区，对应外部 test_ROM
WORK_BASE    内部工作区，对应 MCU 内部 work RAM
OUTPUT_BASE  输出区，对应外部 verify_RAM
```

第一版建议每个区域预留：

```text
0x100 byte
```

程序员视角下，三个区域都按 32-bit 槽位访问，因此相邻槽位地址步长统一为：

```text
+4
```

## 3. 数据访问规则

### 3.1 输入区

输入区每个样本最终来自外部 16-bit signed 数据。

程序视角：

```text
每个输入槽位地址步长为 +4
LDR 读到寄存器里的值已经是符号扩展后的 32-bit signed
```

输入排列：

```text
INPUT_BASE + 0    x0.real
INPUT_BASE + 4    x0.imag
INPUT_BASE + 8    x1.real
INPUT_BASE + 12   x1.imag
...
INPUT_BASE + 56   x7.real
INPUT_BASE + 60   x7.imag
```

示例：

```asm
LDR R0, [R8 + 0]
LDR R1, [R8 + 4]
LDR R2, [R8 + 8]
```

### 3.2 工作区

工作区是 MCU 内部 32-bit 工作 RAM。

程序视角：

```text
每个工作数据地址步长为 +4
LDR / STR 读写的都是 32-bit 数据
```

示例：

```asm
STR R0, [R9 + 0]
STR R1, [R9 + 4]
LDR R2, [R9 + 0]
```

### 3.3 输出区

输出区最终写到外部 verify_RAM，外部仍按 16-bit 样本组织。

程序视角：

```text
输出地址步长为 +4
程序用 STR 把 32-bit 结果写回输出区
底层负责把 32-bit 结果转换成外部需要的 16-bit
```

输出排列：

```text
OUTPUT_BASE + 0    y0.real
OUTPUT_BASE + 4    y0.imag
OUTPUT_BASE + 8    y1.real
OUTPUT_BASE + 12   y1.imag
...
OUTPUT_BASE + 56   y7.real
OUTPUT_BASE + 60   y7.imag
```

示例：

```asm
STR R0, [R10 + 0]
STR R1, [R10 + 4]
```

## 4. 寄存器约定

```text
R0  ~ R7    当前运算数据与中间变量
R8          输入区基址或输入指针
R9          工作区基址或工作指针
R10         输出区基址或输出指针
R11         循环计数器、偏移或临时变量
R12         常量寄存器，例如 23170
R13         预留
R14         BL 链接寄存器
R15         不作为普通寄存器使用
```

第一版不要依赖：

```text
R13 作为栈指针
R14 / BX 作为函数返回机制
程序中直接写 R15
```

寄存器不够时，使用内部 work RAM 暂存，不使用栈。

## 5. V1 baseline 正式支持指令

成员 A 在基础版 FFT 程序中可以直接依赖：

```text
MOV
ADD
SUB
AND
ORR
CMP
LDR
STR
B
BL
BEQ
BNE
MUL
ASR
```

`dsp` 分支为了 V2 packed FFT 加速，额外支持：

```text
SHADD16
SHSUB16
SMUAD
SMUSD
SXTH
PKHBT
```

`dsp` 分支为了 V3 architecture DSP 优化，额外支持 ARM 风格访存：

```text
LDMIA Rn!, {reglist}
STRD Rd, Rm, [Rn + imm]
```

`dsp` 分支为了 V4 ARM-strict exact 优化，额外支持：

```text
SSAX
SSUB16
```

V1 baseline 不要依赖：

```text
BX
函数调用
栈
MLA
packed DSP 指令
批量访存
```

说明：

```text
BL 已用于满足 PPT 标准指令仿真要求，会把 PC + 4 写入 R14。
当前没有 BX，也没有栈/函数调用约定；FFT 程序仍然写成直线代码，不依赖 BL 返回。
```

第一版 FFT 程序建议写成：

```text
直线代码
简单循环或少量条件跳转
不依赖函数式组织
```

当前 FFT baseline 采用完全展开直线代码。

## 6. 指令格式总览

所有指令最高 4 位保留为条件字段：

```text
Instr[31:28] = cond
```

第一版正式使用：

```text
1110 = AL   Always
0000 = EQ   Z == 1
0001 = NE   Z == 0
```

大类字段：

```text
op[27:26] = 00  数据处理类
op[27:26] = 01  访存类
op[27:26] = 10  分支类
op[27:26] = 11  预留扩展
```

普通数据处理和访存默认使用 `AL`；`B` 使用 `AL`；`BEQ` 使用 `EQ`；`BNE` 使用 `NE`。

## 7. 数据处理类

格式：

```text
31        28 27 26 25 24    21 20 19    16 15    12 11                 0
+------------+-----+--+--------+--+--------+--------+--------------------+
|    cond    | 00  | I| opcode | S|   Rn   |   Rd   |      operand2      |
+------------+-----+--+--------+--+--------+--------+--------------------+
```

opcode：

```text
0000 = AND
0100 = ADD
0010 = SUB
1100 = ORR
1101 = MOV
1010 = CMP
1001 = MUL
1111 = ASR
```

`I = 0` 时：

```text
operand2[3:0]  = Rm
operand2[11:4] = 0
```

`I = 1` 时：

```text
operand2[11:0] = imm12
```

立即数是无符号 `imm12`，所以成员 A 程序不能写超过 `4095` 的单条立即数。例如 `23170` 不能写成一条：

```asm
MOV R12, #23170
```

应改为多条 `imm12` 安全指令构造，例如：

```asm
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
```

这样得到：

```text
R12 = 5 * 4095 + 2695 = 23170
```

## 8. 访存类

格式：

```text
31        28 27 26 25 24 23         20 19    16 15    12 11             0
+------------+-----+--+--+-------------+--------+--------+---------------+
|    cond    | 01  | L| U|   reserved  |   Rn   |   Rd   |     imm12     |
+------------+-----+--+--+-------------+--------+--------+---------------+
```

第一版只支持：

```text
LDR Rd, [Rn, #imm12]
STR Rd, [Rn, #imm12]
```

项目文档和当前汇编中也使用等价的人类可读写法：

```asm
LDR Rd, [Rn + imm]
STR Rd, [Rn + imm]
```

机器码翻译时统一按 `imm12` 加偏移处理。

第一版暂不支持：

```text
寄存器偏移
负偏移
pre/post indexing
write-back
批量访存
```

V3 architecture DSP 版例外：为了提高 FFT 输入输出搬运效率，在 `op=11` 扩展类中支持 ARM 风格 `LDMIA/STRD`。这属于加速分支能力，不作为 V1 baseline 必须项。

地址语义：

```text
address = Rn + zero_extend(imm12)
```

三个区域在程序员视角下统一按 32-bit 槽位编址，相邻槽位步长统一为 `+4`。

## 9. 分支类

格式：

```text
31        28 27 26 25 24 23                                   0
+------------+-----+--+--+--------------------------------------+
|    cond    | 10  | 0| L|                imm24                 |
+------------+-----+--+--+--------------------------------------+
```

分支目标计算统一采用：

```text
branch_offset = sign_extend(imm24) << 2
pc_next       = PC + 8 + branch_offset
```

其中：

```text
L = 0: B / BEQ / BNE，不写链接寄存器
L = 1: BL，写 R14 = PC + 4
```

注意：

```text
第一版不要混用 PC + 4 和 PC + 8。
```

## 10. 状态寄存器

当前最保守实现只要求：

```text
CMP 更新状态寄存器
BEQ / BNE 读取 Z
```

成员 A 第一版程序不要依赖 `ADD/SUB` 顺手改 flags。

## 10.1 DSP 扩展类

DSP 加速分支使用原先预留的：

```text
op[27:26] = 11
```

格式：

```text
31        28 27 26 25     21 20 19    16 15    12 11       4 3      0
+------------+-----+---------+--+--------+--------+----------+--------+
|    cond    | 11  |  funct  | 0|   Rn   |   Rd   | reserved |   Rm   |
+------------+-----+---------+--+--------+--------+----------+--------+
```

funct：

```text
00000 = SHADD16
00001 = SHSUB16
00010 = SMUAD
00011 = SMUSD
00100 = SXTH
00101 = PKHBT
00110 = LDMIA
00111 = STRD
01000 = SSAX
01001 = SSUB16
```

其中 `SHADD16` 到 `PKHBT` 用于 `asm/fft8_v2_packed_dsp.s`；`LDMIA/STRD` 用于 `asm/fft8_v3_arch_dsp.s`；`SSAX/SSUB16` 用于 `asm/fft8_v4_arm_strict.s`，不会影响 V1 scalar baseline。

V3 访存扩展格式：

```text
LDMIA:
  op[27:26]     = 11
  funct[25:21]  = 00110
  W[20]         = 1
  Rn[19:16]     = base register
  regmask[15:0] = register list

STRD:
  op[27:26]    = 11
  funct[25:21] = 00111
  reserved[20] = 0
  Rn[19:16]    = base register
  Rd[15:12]    = first source register
  imm8[11:4]   = byte offset, must be multiple of 4
  Rm[3:0]      = second source register
```

V3 限制：

```text
LDMIA 只支持 increment-after 和 writeback。
LDMIA writeback 时，base register 不允许出现在 reglist 中。
LDMIA 不使用 R15，按寄存器编号升序写入。
STRD 写 base+imm 和 base+imm+4 两个连续 32-bit 程序槽位。
V3 不实现 FFT8、fixed twiddle 复乘或自定义 complex load/store 指令。
V4 也不实现 FFT8、fixed twiddle 复乘或自定义 complex load/store 指令，只新增 ARM 真实 SIMD/DSP 风格 `SSAX/SSUB16`。
```

V4 packed lane 指令语义：

```text
SSAX Rd, Rn, Rm:
  Rd.low16  = signed16(Rn.low16)  + signed16(Rm.high16)
  Rd.high16 = signed16(Rn.high16) - signed16(Rm.low16)

SSUB16 Rd, Rn, Rm:
  Rd.low16  = signed16(Rn.low16)  - signed16(Rm.low16)
  Rd.high16 = signed16(Rn.high16) - signed16(Rm.high16)

两条指令都按 16-bit lane 截断/回绕，不饱和，不实现 APSR.GE flags。
```

## 11. FFT 算法约定

成员 A 第一版程序采用：

```text
8 点复数正向 FFT
radix-2 DIF
完全展开
real / imag 分开
每级蝶形后 ASR #1
最终输出 = FFT(input) / 8
```

旋转因子：

```text
W8^0 = 1
W8^1 =  0.7071 - j0.7071
W8^2 = -j
W8^3 = -0.7071 - j0.7071
```

Q15 常量：

```text
0.70710678 -> 23170
```

DIF 自然输出顺序为 bit-reversal：

```text
X0, X4, X2, X6, X1, X5, X3, X7
```

如果验收要求自然序，只需调整最后写 `OUTPUT_BASE` 的顺序，不需要改计算主体。

## 12. 第一版最终需求

成员 2 第一版 MCU 请优先实现：

```text
32-bit 定长指令
32-bit 寄存器
32-bit 内部数据通路
统一字节寻址
三个区域程序视角统一 32-bit 槽位、+4 步长
输入区 LDR：底层 16-bit signed -> 寄存器 32-bit signed
工作区 LDR/STR：32-bit
输出区 STR：寄存器 32-bit -> 外部 16-bit
MOV / ADD / SUB / CMP
B / BL / BEQ / BNE，PC + 8 分支语义
AND / ORR
LDR / STR 立即数偏移
signed MUL，结果取 32-bit
ASR #imm，至少支持 #1 和 #15
DSP 加速分支额外支持 SHADD16 / SHSUB16 / SMUAD / SMUSD / SXTH / PKHBT
V3 architecture DSP 分支额外支持 ARM 风格 LDMIA / STRD
V4 ARM-strict exact 分支额外支持 ARM SIMD/DSP 风格 SSAX / SSUB16
```

最关键的最新变化：

```text
1. INPUT_BASE / WORK_BASE / OUTPUT_BASE = 0x000 / 0x100 / 0x200。
2. 输入区、工作区、输出区程序视角步长统一为 +4。
3. 数据处理和访存立即数是 imm12，单条立即数不能超过 4095。
```
