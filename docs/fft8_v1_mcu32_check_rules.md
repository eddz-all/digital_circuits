# FFT8 MCU32 第一版对拍规则

本文档匹配当前老师 `测试数据样例-2026` 的 DFT/FFT COE 顺序，以及：

```text
asm/fft8_v1_mcu32_basic.s
tools/test_fft8_v1_mcu32_basic.py
tools/assemble_mcu_v1.py
rtl/mcu_fft_system.vhd
tb/mcu_v1_core_tb.vhd
tb/mcu_fft_system_tb.vhd
```

## 1. 变换定义

当前第一版程序按老师样例计算 8 点复数 DFT：

```text
X[k] = sum_n x[n] * W[k,n]
```

其中 `W[k,n]` 等价于 `FFT_input.coe` 中的 DFT 变换矩阵。当前 DSP fast
path 不再运行时读取前 128 个矩阵槽，而是用 bit-reversed input 的 radix-2
DIT packed FFT butterfly 计算等价结果。程序不做旧版 radix-2 DIF 的每级
`/2` 缩放，因此输出不是 `FFT(input) / 8`；最终输出仍是自然顺序。

## 2. 输入 COE 顺序

`FFT_input.coe` 中每个值都是 16-bit signed，程序视角按 32-bit 槽位 `+4`
访问。以 COE value index 计：

```text
0..63     DFT 变换矩阵实部，Q7，按第 1 行第 1..8 列、第 2 行第 1..8 列...排列
64..127   DFT 变换矩阵虚部，Q7，同上
128..135  原始信号实部，Q5
136..143  原始信号虚部，Q5
```

对应程序地址：

```text
matrix_real[k,n] = input slot (k * 8 + n),       byte address (k * 8 + n) * 4
matrix_imag[k,n] = input slot (64 + k * 8 + n),  byte address (64 + k * 8 + n) * 4
signal_real[n]   = input slot (128 + n),         byte address (128 + n) * 4
signal_imag[n]   = input slot (136 + n),         byte address (136 + n) * 4
```

## 3. 输出顺序

`FFT_output.coe` 的 16 个值按自然序排列：

```text
slot 0..7   X0.re, X1.re, X2.re, X3.re, X4.re, X5.re, X6.re, X7.re
slot 8..15  X0.im, X1.im, X2.im, X3.im, X4.im, X5.im, X6.im, X7.im
```

输出为 16-bit signed Q12。当前汇编把实部写到程序地址 `0x800..0x81c`，
把虚部写到 `0x820..0x83c`；`mcu_v1_data_mem` 将这些地址映射到外部
`output_mem` slot `0..15`。

## 4. 外部系统接口

仿照 `origin/board-files-docs` 中 `MCU_v1/BOARD_TOP/.../mcu_fft_system.vhd`
的外部连接方式，当前本地增加了 GHDL 可验证的：

```text
rtl/mcu_fft_system.vhd
```

修正后的接口口径：

```text
test_rom_addr      8-bit, 访问 FFT_input.coe slot 0..143
test_vector_in     16-bit signed
verify_ram_addr    6-bit, 写 FFT_output.coe slot 0..15
verify_vector_out  16-bit signed
```

`mcu_fft_system` 会在 core 保持 reset 时用连续输入流把 `FFT_input.coe[128..143]`
这 16 个 signal 槽写入 `input_mem[128..143]`，然后释放 core；core 停机后再把
16 个输出槽转写到外部 verify RAM 接口。

## 5. 定点规则

输入信号为 Q5，矩阵系数为 Q7，所以每次乘法直接得到 Q12：

```text
real_acc += xr * wr
real_acc -= xi * wi
imag_acc += xr * wi
imag_acc += xi * wr
```

当前程序不使用 Q15 旋转因子常数 `23170`，也不使用 `ASR #1` 做 FFT 级间缩放。

## 5.1 当前 DSP fast path

当前汇编使用这些 packed DSP 指令：

```text
PKHBT Rd, Rn, Rm, LSL #16
SADD16 Rd, Rn, Rm
SSUB16 Rd, Rn, Rm
SSAX Rd, Rn, Rm
SMUAD Rd, Rn, Rm
SMUSD Rd, Rn, Rm
STMIA Rn!, {register list}
```

`PKHBT` 把 real/imag 打包成一个 32-bit complex 值，`SADD16/SSUB16`
做 lane-wise butterfly 加减，`SSAX` 做 `-j` 旋转，`SMUAD/SMUSD`
做 W8^1/W8^3 的 packed 复乘，`STMIA` 批量写回 real0..real7 和
imag0..imag7。当前程序按 bit-reversed 顺序加载：

```text
x0, x4, x2, x6, x1, x5, x3, x7
```

每个输入先由 Q5 乘 128 放大为 Q12 packed complex lane，三层 radix-2
DIT butterfly 后得到自然序 Q12 输出。

## 6. 本地检查

host-side 解释器检查：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
```

机器码生成：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s --mem-out asm/fft8_v1_mcu32_basic.mem --lst-out asm/fft8_v1_mcu32_basic.lst
```

GHDL 检查：

```bash
ghdl -a --std=08 rtl/mcu_v1_decoder.vhd rtl/mcu_v1_alu.vhd rtl/mcu_v1_regfile.vhd rtl/mcu_v1_instr_rom.vhd rtl/mcu_v1_data_mem.vhd rtl/mcu_v1_core.vhd rtl/mcu_fft_system.vhd tb/mcu_v1_decoder_tb.vhd tb/mcu_v1_core_tb.vhd tb/mcu_fft_system_tb.vhd
ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb --assert-level=error
ghdl -e --std=08 mcu_v1_core_tb
ghdl -r --std=08 mcu_v1_core_tb --assert-level=error
ghdl -e --std=08 mcu_fft_system_tb
ghdl -r --std=08 mcu_fft_system_tb --assert-level=error
```

当前编码检查结果：

```text
encoded 106 instructions from asm/fft8_v1_mcu32_basic.s
DONE at PC 0x01A4, word 0xE8FFFFFE
```

当前 host checker 结果：

```text
teacher sample passed
100 random Q5 signal tests passed against the sample DFT matrix
timed_steps = 100
```

当前 GHDL system 结果：

```text
mcu_fft_system_tb cnt_cycles 138
```
