# FFT 算法程序对接说明

这份文档给 FFT 汇编/算法同学参考，目标是让 MCU 程序直接适配老师提供的 `FFT_input.coe`、`FFT_output.coe` 和 `coe文件说明.docx`。

## 1. 板级壳子的当前约定

当前 DSP fast path 已切到 packed radix-2 FFT butterfly。板级 `test_ROM`
仍然使用完整 `FFT_input.coe`，但 MCU 运行时只读取最后 16 个原始信号槽：

```text
test_ROM[128] -> input_mem[128]
test_ROM[129] -> input_mem[129]
...
test_ROM[143] -> input_mem[143]
```

输出也是顺序导出：

```text
output_mem[0]  -> verify_RAM[0]
output_mem[1]  -> verify_RAM[1]
...
output_mem[15] -> verify_RAM[15]
```

也就是说，板级不再做 `0,8,1,9...` 这种地址重排，也不再把前
128 个 DFT 矩阵槽装入 MCU 输入内存。FFT 程序直接按照老师 COE
的数据布局读取信号槽，并用 bit-reversed input 的 radix-2 DIT 计算等价的老师
Q7 DFT 结果。

## 2. 老师 FFT_input.coe 的结构

老师提供的 `FFT_input.coe` 不是单纯 16 个输入点，而是：

```text
第 1  - 64  个数据：DFT 变换矩阵实部，8x8，Q7
第 65 - 128 个数据：DFT 变换矩阵虚部，8x8，Q7
第 129-136 个数据：原始输入信号实部，8 个，Q5
第 137-144 个数据：原始输入信号虚部，8 个，Q5
```

当前 DSP fast path 只从 `test_ROM` 读取最后 16 个原始输入信号。也就是：

```text
input_mem[128..135] = real0, real1, ..., real7
input_mem[136..143] = imag0, imag1, ..., imag7
```

因此 FFT 程序读取第 `i` 个复数输入时，应该使用：

```text
real_i = input_mem[128 + i]
imag_i = input_mem[136 + i]
```

不要再按交错格式读取：

```text
real_i = input_mem[2*i]
imag_i = input_mem[2*i + 1]
```

## 3. 老师 FFT_output.coe 的结构

老师提供的 `FFT_output.coe` 是 16 个数据：

```text
output[0..7]  = real0, real1, ..., real7
output[8..15] = imag0, imag1, ..., imag7
```

因此 MCU 程序最终也应该写成：

```text
output_mem[0..7]  = 输出实部
output_mem[8..15] = 输出虚部
```

不要写成交错格式：

```text
real0, imag0, real1, imag1, ...
```

## 4. 定点格式必须对齐

当前最明显的问题是定点缩放不一致。

老师文件的格式是：

```text
输入信号：Q5
DFT 矩阵系数：Q7
输出结果：Q12
```

含义如下：

```text
Q5  ：实际值 = int16 / 2^5
Q7  ：实际值 = int16 / 2^7
Q12 ：实际值 = int16 / 2^12
```

如果用矩阵乘法理解：

```text
Q5 输入 * Q7 系数 = Q12 乘积
多个 Q12 乘积相加后，最终仍然应该按 Q12 输出
```

所以如果程序内部用了 Q15 旋转因子，例如：

```text
0.7071 -> 0x5a82
```

就必须重新检查乘法后的右移位数。否则输出会变成完全不同的尺度。

## 5. 旋转因子/系数问题

老师 `FFT_input.coe` 前 128 个数据给的是 DFT 矩阵：

```text
1.0       -> 0080
0.7071    -> 005b
-0.7071   -> ffa5
-1.0      -> ff80
```

这些是 Q7 系数。

当前 DSP fast path 不直接读取这 128 个矩阵数据，而是把老师 `dftmtx(8)`
对应的 Q7 系数等价分解到 radix-2 butterfly 中：`128/-128` 通过 Q5 输入先乘
128 变成 Q12 和 `SSAX` 的 `-j` 旋转处理，`91/-91` 通过 `SMUAD/SMUSD`
复乘后 `ASR #7` 回到 Q12。实现时必须保证：

```text
数学方向一致
符号一致
定点小数位一致
乘法右移一致
最终输出 Q12 一致
```

否则即使 FFT 数学结构看起来正确，输出十六进制也会和老师 `FFT_output.coe` 对不上。

## 6. DFT/FFT 方向要确认

老师 MATLAB 中使用：

```matlab
dft_mat = dftmtx(8);
signal_fft = signal * dft_mat;
```

算法程序需要确认自己实现的是同方向的 DFT/FFT，不是 IFFT，也不是旋转因子虚部符号相反的版本。

如果虚部符号整体相反，或者旋转因子取了共轭，结果会和老师参考输出不同。

## 7. 输出顺序要确认

很多 FFT 蝶形算法可能产生 bit-reversal 顺序输出。老师输出是自然顺序：

```text
real0, real1, real2, ..., real7,
imag0, imag1, imag2, ..., imag7
```

如果算法内部输出是位反转顺序，需要在程序最后重排后再写入 `output_mem`。

8 点 FFT 的位反转顺序常见为：

```text
0, 4, 2, 6, 1, 5, 3, 7
```

是否需要重排取决于具体 FFT 算法实现。

## 8. 当前老师样例数据

当前从老师 `FFT_input.coe` 提取的 16 个原始输入是：

```text
real: fff3, ffe3, ffe3, 0000, fff7, 001b, 0006, 0014
imag: 001b, fff7, ffee, ffe9, 0000, 0012, ffeb, ffec
```

按 16-bit 有符号整数看：

```text
real: -13, -29, -29, 0, -9, 27, 6, 20
imag: 27, -9, -18, -23, 0, 18, -21, -20
```

按 Q5 实际值看，需要除以 32。

老师 `FFT_output.coe` 期望输出是：

```text
real: f280, e80a, 1a80, fea2, e080, 16f6, e680, fa5e
imag: e900, 317c, 2c00, 1f8c, 0b00, 0c84, 1600, d874
```

按 16-bit 有符号整数看：

```text
real: -3456, -6134, 6784, -350, -8064, 5878, -6528, -1442
imag: -5888, 12668, 11264, 8076, 2816, 3204, 5632, -10124
```

按 Q12 实际值看，需要除以 4096。

## 9. 建议验证方式

建议算法同学先不要上板，先用软件或 MCU 仿真逐步验证：

```text
1. 按 input_mem[128..135] 实部、input_mem[136..143] 虚部读入。
2. 确认输入按 Q5 解释。
3. 确认旋转因子或 DFT 矩阵按 Q7 或等价格式解释。
4. 确认乘法和累加后最终输出为 Q12。
5. 确认输出顺序是先 8 实、再 8 虚。

## 10. 当前 DSP 指令实现口径

当前 MCU RTL 额外支持这些 DSP / bulk-store 指令：

```text
PKHBT Rd, Rn, Rm, LSL #16  -> Rd = {Rm[15:0], Rn[15:0]}
SADD16 Rd, Rn, Rm          -> packed lane-wise signed add
SSUB16 Rd, Rn, Rm          -> packed lane-wise signed subtract
SSAX Rd, Rn, Rm            -> low = Rn.low + Rm.high, high = Rn.high - Rm.low
SMUAD Rd, Rn, Rm           -> Rd = Rn.low*Rm.low + Rn.high*Rm.high
SMUSD Rd, Rn, Rm           -> Rd = Rn.low*Rm.low - Rn.high*Rm.high
SMLAD Rd, Rn, Rm, Ra       -> packed dual multiply accumulate
STMIA Rn!, {reglist}       -> store multiple, increment after, writeback
```

DSP 版 FFT 程序把 8 个复数样本打包成 8 个寄存器，packed complex 格式为：

```text
low16 = real Q12
high16 = imag Q12
```

输入加载顺序为 `x0, x4, x2, x6, x1, x5, x3, x7`，三层 radix-2 DIT
butterfly 后直接输出自然序。旋转因子仍然只来自老师 `dftmtx(8)` 的 Q7
常数集合 `0, 128, -128, 91, -91`。

本地 host checker 实测：

```text
107 instructions before labels/comments
106 instructions executed before DONE self-loop
100 instructions from first input read through last output write
```
6. 用老师 FFT_output.coe 对比 16 个十六进制结果。
```

如果最终输出和老师文件逐项一致，再交给板级上板验证。
