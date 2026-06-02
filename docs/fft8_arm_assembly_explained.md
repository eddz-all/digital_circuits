# 8 点 FFT ARM 汇编说明

对应汇编文件：

```text
asm/fft8_dif_q15_armv7em.s
```

这个文件不是给电脑直接运行的，而是给你们自己设计的 MCU 作为目标指令程序。硬件同学需要在 Vivado 里实现这些 ARM/Thumb-2 DSP 指令的功能。

## 1. 总体目标

实现一个 8 点复数正向 FFT：

```text
X[k] = sum x[n] * exp(-j * 2*pi*k*n/8)
```

采用 radix-2 DIF FFT，完全展开，无循环。

输出是 bit-reversal 顺序：

```text
X0, X4, X2, X6, X1, X5, X3, X7
```

每级蝶形使用 `(a+b)/2` 和 `(a-b)/2`，一共 3 级，所以最终输出是：

```text
FFT(input) / 8
```

## 2. 数据格式

每个复数用一个 32-bit 寄存器保存：

```text
bit[15:0]   = real，16-bit signed Q15
bit[31:16]  = imag，16-bit signed Q15
```

例如：

```text
r0 = {imag[15:0], real[15:0]}
```

硬件里所有 halfword 都要按 signed 16-bit 理解。

## 3. 寄存器分配

函数入口：

```text
r0 = 输入数组地址，指向 8 个 packed complex word
r1 = 输出数组地址，指向 8 个 packed complex word
```

汇编开始后：

```asm
mov r10, r0
mov r11, r1
```

所以：

```text
r10 = 输入指针
r11 = 输出指针
```

然后：

```asm
movw r12, #0x5A82
movt r12, #0x5A82
```

得到：

```text
r12 = 0x5A825A82
```

也就是两个 halfword 都是 `0x5A82`。这个数是：

```text
0.70710678 的 Q15 表示，约等于 23170
```

加载输入后：

```text
r0 = x0
r1 = x1
r2 = x2
r3 = x3
r4 = x4
r5 = x5
r6 = x6
r7 = x7
```

临时寄存器：

```text
r8  = 临时 packed complex 或乘法中间值
r9  = 乘法中间值
r10 = 输入指针
r11 = 输出指针
r12 = 0x5A825A82 常数
```

## 4. 需要硬件实现的指令

### 4.1 MOV

示例：

```asm
mov r10, r0
```

语义：

```text
r10 = r0
```

硬件模块：

```text
寄存器堆读端口 -> 写回端口
```

建议：

```text
1 cycle
```

### 4.2 MOVW / MOVT

示例：

```asm
movw r12, #0x5A82
movt r12, #0x5A82
```

语义：

```text
MOVW: r12[15:0]  = 0x5A82
MOVT: r12[31:16] = 0x5A82
```

执行后：

```text
r12 = 0x5A825A82
```

硬件模块：

```text
立即数扩展器 + halfword 写入逻辑
```

如果你们为了简化，也可以把 `0x5A825A82` 做成常量寄存器，程序开始时直接可用。

### 4.3 LDMIA.W

示例：

```asm
ldmia.w r10!, {r0-r7}
```

语义：

```text
r0 = MEM[r10 + 0]
r1 = MEM[r10 + 4]
r2 = MEM[r10 + 8]
r3 = MEM[r10 + 12]
r4 = MEM[r10 + 16]
r5 = MEM[r10 + 20]
r6 = MEM[r10 + 24]
r7 = MEM[r10 + 28]
r10 = r10 + 32
```

这里每个数据是 32-bit packed complex。

硬件模块：

```text
load/store unit
地址生成器
数据 RAM / 外部 test_ROM 读接口
寄存器堆写回
```

如果你们 MCU 不想实现完整 `LDMIA`，也可以用 8 条 `LDR` 替代。但速度会慢一些。

### 4.4 STMIA.W

示例：

```asm
stmia.w r11!, {r0-r7}
```

语义：

```text
MEM[r11 + 0]  = r0
MEM[r11 + 4]  = r1
MEM[r11 + 8]  = r2
MEM[r11 + 12] = r3
MEM[r11 + 16] = r4
MEM[r11 + 20] = r5
MEM[r11 + 24] = r6
MEM[r11 + 28] = r7
r11 = r11 + 32
```

输出顺序就是：

```text
r0, r1, r2, r3, r4, r5, r6, r7
= X0, X4, X2, X6, X1, X5, X3, X7
```

如果验收要求自然序，可以改成逐个 `STR`，按地址写：

```text
X0 -> out[0]
X1 -> out[1]
X2 -> out[2]
X3 -> out[3]
X4 -> out[4]
X5 -> out[5]
X6 -> out[6]
X7 -> out[7]
```

但最快是当前 bit-reversal 直接写出。

### 4.5 SHADD16

示例：

```asm
shadd16 r8, r0, r4
```

ARM 语义：

```text
r8[15:0]  = signed((r0[15:0]  + r4[15:0])  >> 1)
r8[31:16] = signed((r0[31:16] + r4[31:16]) >> 1)
```

也就是对两个 16-bit 分量分别做：

```text
(a + b) / 2
```

在 packed complex 里等价于：

```text
real = (a.real + b.real) / 2
imag = (a.imag + b.imag) / 2
```

硬件模块：

```text
两个 signed 16-bit 加法器
两个算术右移 1 位
打包输出
```

FFT 用途：

```text
蝶形上支路：(a+b)/2
```

### 4.6 SHSUB16

示例：

```asm
shsub16 r4, r0, r4
```

ARM 语义：

```text
r4[15:0]  = signed((r0[15:0]  - r4[15:0])  >> 1)
r4[31:16] = signed((r0[31:16] - r4[31:16]) >> 1)
```

也就是：

```text
real = (a.real - b.real) / 2
imag = (a.imag - b.imag) / 2
```

硬件模块：

```text
两个 signed 16-bit 减法器
两个算术右移 1 位
打包输出
```

FFT 用途：

```text
蝶形下支路：(a-b)/2
```

### 4.7 SMUAD

示例：

```asm
smuad r8, r5, r12
```

ARM 语义：

```text
r8 = signed16(r5[15:0])  * signed16(r12[15:0])
   + signed16(r5[31:16]) * signed16(r12[31:16])
```

因为：

```text
r5  = {imag, real}
r12 = {C, C}
C   = 0x5A82
```

所以：

```text
r8 = real*C + imag*C
   = C*(real + imag)
```

硬件模块：

```text
两个 signed 16x16 乘法器
一个 32-bit 加法器
输出 32-bit signed 结果
```

在 Kintex-7 上建议用 DSP slice。

### 4.8 SMUSD

示例：

```asm
smusd r9, r5, r12
```

ARM 语义：

```text
r9 = signed16(r5[15:0])  * signed16(r12[15:0])
   - signed16(r5[31:16]) * signed16(r12[31:16])
```

因为：

```text
r5  = {imag, real}
r12 = {C, C}
```

所以：

```text
r9 = real*C - imag*C
   = C*(real - imag)
```

硬件模块：

```text
两个 signed 16x16 乘法器
一个 32-bit 减法器
输出 32-bit signed 结果
```

### 4.9 RSB

示例：

```asm
rsb r9, r9, #0
```

语义：

```text
r9 = 0 - r9
```

也就是取负数。

硬件模块：

```text
32-bit 减法器
```

在 FFT 里用于改变旋转因子的符号。

### 4.10 ASR

示例：

```asm
asr r8, r8, #15
```

语义：

```text
r8 = signed(r8) >>> 15
```

注意是算术右移，最高位补符号位。

用途：

`SMUAD/SMUSD` 得到的是 Q15 * Q15 的结果，量纲是 Q30。右移 15 位后回到 Q15：

```text
Q30 >> 15 = Q15
```

硬件模块：

```text
32-bit barrel shifter
```

如果只支持固定右移 15，也可以做成简单布线加符号扩展。

### 4.11 PKHBT

示例：

```asm
pkhbt r5, r8, r9, lsl #16
```

语义：

```text
r5[15:0]  = r8[15:0]
r5[31:16] = r9[15:0]
```

因为 `r9` 先左移 16，所以它的低 halfword 被放到结果高 halfword。

用途：

把两个 32-bit 计算结果重新打包成一个 packed complex：

```text
r5.real = r8[15:0]
r5.imag = r9[15:0]
```

硬件模块：

```text
16-bit 选择/拼接逻辑
```

### 4.12 SXTH

示例：

```asm
sxth r8, r6
```

语义：

```text
r8 = sign_extend(r6[15:0])
```

也就是取 packed complex 的 real 部分，并扩展成 32-bit signed。

硬件模块：

```text
符号扩展器
```

### 4.13 BX LR

示例：

```asm
bx lr
```

语义：

```text
PC = LR
```

在完整 ARM 函数里这是返回调用者。

如果你们课程测试不是函数调用，而是 MCU 从固定入口执行，也可以把最后改成停止信号或跳转到结束状态。

## 5. 三个复数乘法宏

FFT 里 8 点旋转因子只有 4 个：

```text
W8^0 = 1
W8^1 =  0.7071 - j0.7071
W8^2 = -j
W8^3 = -0.7071 - j0.7071
```

`W8^0` 不需要乘法。

### 5.1 CMUL_W1

宏：

```asm
CMUL_W1 rd, rn, tmp_sum, tmp_diff
```

计算：

```text
rd = rn * (0.7071 - j0.7071)
```

设：

```text
rn = real + j*imag
C  = 0.7071
```

数学结果：

```text
(real + j*imag) * (C - jC)
= C*(real + imag) + j*C*(imag - real)
```

对应汇编：

```asm
smuad tmp_sum,  rn, r12   ; tmp_sum  = C*(real + imag)
smusd tmp_diff, rn, r12   ; tmp_diff = C*(real - imag)
rsb   tmp_diff, tmp_diff, #0
asr   tmp_sum,  tmp_sum, #15
asr   tmp_diff, tmp_diff, #15
pkhbt rd, tmp_sum, tmp_diff, lsl #16
```

最后：

```text
rd.real = C*(real + imag) >> 15
rd.imag = C*(imag - real) >> 15
```

### 5.2 CMUL_W3

宏：

```asm
CMUL_W3 rd, rn, tmp_sum, tmp_diff
```

计算：

```text
rd = rn * (-0.7071 - j0.7071)
```

数学结果：

```text
(real + j*imag) * (-C - jC)
= C*(imag - real) + j*(-C*(real + imag))
```

对应汇编：

```asm
smuad tmp_sum,  rn, r12   ; tmp_sum  = C*(real + imag)
smusd tmp_diff, rn, r12   ; tmp_diff = C*(real - imag)
rsb   tmp_diff, tmp_diff, #0
rsb   tmp_sum,  tmp_sum, #0
asr   tmp_diff, tmp_diff, #15
asr   tmp_sum,  tmp_sum, #15
pkhbt rd, tmp_diff, tmp_sum, lsl #16
```

最后：

```text
rd.real = C*(imag - real) >> 15
rd.imag = -C*(real + imag) >> 15
```

### 5.3 CMUL_NEG_J

宏：

```asm
CMUL_NEG_J rd, rn, tmp_real, tmp_imag
```

计算：

```text
rd = rn * (-j)
```

设：

```text
rn = real + j*imag
```

则：

```text
(real + j*imag) * (-j)
= imag - j*real
```

也就是：

```text
rd.real = imag
rd.imag = -real
```

对应汇编：

```asm
sxth tmp_real, rn
asr  tmp_imag, rn, #16
rsb  tmp_real, tmp_real, #0
pkhbt rd, tmp_imag, tmp_real, lsl #16
```

注意：

```text
sxth tmp_real, rn      取 real
asr tmp_imag, rn, #16 取 imag
rsb tmp_real, #0       得到 -real
```

最后打包成：

```text
{imag = -real, real = imag}
```

## 6. FFT 数据流

### 6.1 Stage 1

处理 4 组蝶形：

```text
(x0, x4)
(x1, x5)
(x2, x6)
(x3, x7)
```

对应公式：

```text
a0 = (x0 + x4) / 2
b0 = (x0 - x4) / 2 * W8^0

a1 = (x1 + x5) / 2
b1 = (x1 - x5) / 2 * W8^1

a2 = (x2 + x6) / 2
b2 = (x2 - x6) / 2 * W8^2

a3 = (x3 + x7) / 2
b3 = (x3 - x7) / 2 * W8^3
```

寄存器结果：

```text
r0 = a0
r1 = a1
r2 = a2
r3 = a3
r4 = b0
r5 = b1
r6 = b2
r7 = b3
```

### 6.2 Stage 2

处理两个 4 点组：

```text
(a0, a2), (a1, a3)
(b0, b2), (b1, b3)
```

带旋转因子的位置乘以 `-j`。

寄存器结果：

```text
r0 = c0
r1 = c1
r2 = d0
r3 = d1
r4 = e0
r5 = e1
r6 = f0
r7 = f1
```

### 6.3 Stage 3

处理四个 2 点蝶形：

```text
(r0, r1)
(r2, r3)
(r4, r5)
(r6, r7)
```

最终：

```text
r0 = X0
r1 = X4
r2 = X2
r3 = X6
r4 = X1
r5 = X5
r6 = X3
r7 = X7
```

这就是 bit-reversal 输出顺序。

## 7. 建议的硬件模块划分

单核单发射 MCU 至少需要：

```text
1. 指令 ROM
2. PC 和取指逻辑
3. 指令译码器
4. 32-bit 寄存器堆
5. packed 16-bit SIMD 加减单元
6. 32-bit ALU / 取负单元
7. signed 16x16 双乘法 DSP 单元
8. 移位/符号扩展/打包单元
9. Load/store 单元
10. 数据 RAM / ROM 接口
11. 完成信号或结束状态
```

### 7.1 SIMD 加减单元

支持：

```text
SHADD16
SHSUB16
```

输入：

```text
A[31:0], B[31:0]
```

输出：

```text
Y[15:0]  = (signed16(A[15:0])  +/- signed16(B[15:0]))  >>> 1
Y[31:16] = (signed16(A[31:16]) +/- signed16(B[31:16])) >>> 1
```

### 7.2 DSP 乘法单元

支持：

```text
SMUAD
SMUSD
```

输入：

```text
A[31:0], B[31:0]
```

拆分：

```text
a_lo = signed16(A[15:0])
a_hi = signed16(A[31:16])
b_lo = signed16(B[15:0])
b_hi = signed16(B[31:16])
```

输出：

```text
SMUAD = a_lo*b_lo + a_hi*b_hi
SMUSD = a_lo*b_lo - a_hi*b_hi
```

建议：

```text
用两个 DSP slice 或等效乘法器并行完成
```

### 7.3 打包/移位单元

支持：

```text
ASR
SXTH
PKHBT
```

`PKHBT rd, rn, rm, lsl #16` 在本程序里只需要这一种形式：

```text
rd[15:0]  = rn[15:0]
rd[31:16] = rm[15:0]
```

### 7.4 Load/store 单元

为了速度，建议支持：

```text
LDMIA.W base!, {r0-r7}
STMIA.W base!, {r0-r7}
```

如果实现困难，可改写为：

```text
LDR r0, [r10, #0]
LDR r1, [r10, #4]
...
STR r0, [r11, #0]
STR r1, [r11, #4]
...
```

但指令数会增加，速度变慢。

## 8. 这份汇编实际用到的指令清单

```text
MOV
MOVW
MOVT
LDMIA.W
STMIA.W
SHADD16
SHSUB16
SMUAD
SMUSD
RSB
ASR
PKHBT
SXTH
BX
```

没有使用：

```text
普通 ADD/SUB 做 FFT 蝶形
MUL
除法
浮点
循环分支
查表
饱和指令
```

## 9. 对 Vivado 实现最重要的注意点

1. `SHADD16/SHSUB16` 必须按 signed 16-bit 做算术右移。
2. `SMUAD/SMUSD` 的两个 halfword 乘法都必须是 signed 16x16。
3. `ASR #15` 必须是 signed 算术右移，不是逻辑右移。
4. `PKHBT` 在本程序里只需要实现 `lsl #16` 这一种形式。
5. 当前输出是 bit-reversal 顺序，不是自然顺序。
6. 当前结果是 `FFT/8`，因为每级都做了 `/2`。
7. 当前没有饱和，要求输入幅度不要过大，否则仍可能出现 16-bit 截断误差。

