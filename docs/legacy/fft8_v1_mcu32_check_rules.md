# FFT8 MCU32 第一版对拍规则

本文档给成员 3 对拍使用，匹配：

```text
asm/fft8_v1_mcu32_basic.s
tools/test_fft8_v1_mcu32_basic.py
tools/assemble_mcu_v1.py
```

## 1. 变换定义

第一版程序计算：

```text
8 点复数正向 FFT
输出 = FFT(input) / 8
```

正向 FFT 使用：

```text
exp(-j * 2*pi*k*n/8)
```

程序采用 radix-2 DIF，并在每一级蝶形后做一次 `ASR #1`，所以总缩放是 `/8`。

## 2. 数据格式

外部输入和输出均为 16-bit signed，但成员 A 写程序时按 32-bit 槽位访问。数据按 real / imag 交错排列：

```text
re0, im0, re1, im1, re2, im2, re3, im3,
re4, im4, re5, im5, re6, im6, re7, im7
```

MCU 内部寄存器和工作 RAM 按 32-bit signed 计算。`LDR` 输入区时，底层完成 `16-bit signed -> 32-bit signed` 符号扩展；`STR` 输出区时，底层完成 `32-bit -> 外部 16-bit` 转换。

最新基址：

```text
INPUT_BASE   = 0x00000000
WORK_BASE    = 0x00000100
OUTPUT_BASE  = 0x00000200
```

输入地址步长：

```text
INPUT_BASE + 0, +4, +8, ..., +60
```

工作区地址步长：

```text
WORK_BASE + 0, +4, +8, ..., +60
```

输出地址步长：

```text
OUTPUT_BASE + 0, +4, +8, ..., +60
```

## 3. 输出顺序

DIF 第一版默认输出 bit-reversal 顺序：

```text
X0, X4, X2, X6, X1, X5, X3, X7
```

输出仍然按每个复数的 real / imag 交错排列：

```text
slot 0  X0.re
slot 1  X0.im
slot 2  X4.re
slot 3  X4.im
slot 4  X2.re
slot 5  X2.im
slot 6  X6.re
slot 7  X6.im
slot 8  X1.re
slot 9  X1.im
slot 10 X5.re
slot 11 X5.im
slot 12 X3.re
slot 13 X3.im
slot 14 X7.re
slot 15 X7.im
```

如果最终验收要求自然序，只需要调整汇编末尾写 `OUTPUT_BASE` 的顺序。

## 4. 定点细节

每个蝶形先算和差，再算术右移 1 位：

```text
sum  = (a + b) >> 1
diff = (a - b) >> 1
```

`0.70710678` 使用 Q15 常数：

```text
23170
```

最新指令格式的立即数是 `imm12`，所以汇编不能用单条 `MOV R12, #23170`。当前程序用多条 `imm12` 安全指令构造：

```asm
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
```

结果：

```text
R12 = 23170
```

乘法规则：

```text
mul_0p707(value) = (value * 23170) >> 15
```

右移必须是算术右移，负数向负无穷取整。

## 5. 对拍脚本

运行：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
```

脚本会直接解释执行 `asm/fft8_v1_mcu32_basic.s`，同时检查：

```text
1. 汇编只使用第一版允许指令
2. 所有数据处理和访存立即数符合 imm12
3. 输入区按 +4 槽位读 16-bit signed 并符号扩展
4. 工作区按 +4 读写 32-bit signed
5. 输出区按 +4 槽位写出 16-bit signed
6. 汇编结果与独立定点模型一致
7. 定点结果接近浮点 DFT/8 参考值
```

当前脚本还会打印两组简单样例和指令统计。

当前固定测试规模：

```text
7 组边界/极值样例
1000 组中等幅度随机样例
5000 组完整 16-bit 范围随机样例
```

## 6. 编码级检查

运行：

```bash
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
```

该工具会按最新版 `第一版MCU指令格式说明.md` 进行机器码编码检查：

```text
1. 数据处理类按 cond/op/I/opcode/S/Rn/Rd/operand2 编码
2. 访存类按 cond/op/L/U/Rn/Rd/imm12 编码
3. 分支类按 cond/op/imm24 编码
4. 数据处理和访存立即数必须能放进 imm12
5. 分支目标必须符合 PC + 8 规则，imm24 必须可表示
```

已生成：

```text
asm/fft8_v1_mcu32_basic.mem
asm/fft8_v1_mcu32_basic.lst
```

其中 `DONE: B DONE` 当前编码检查结果：

```text
DONE at PC 0x0474, word 0xE8FFFFFE
```

含义：

```text
target = PC
delta = target - (PC + 8) = -8
imm24 = -2
```

这与最新版分支规则 `pc_next = PC + 8 + (sign_extend(imm24) << 2)` 一致。
