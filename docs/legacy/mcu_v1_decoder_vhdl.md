# MCU V1 Decoder VHDL 说明

本文档对应：

```text
rtl/mcu_v1_decoder.vhd
tb/mcu_v1_decoder_tb.vhd
```

## 1. 功能

`mcu_v1_decoder.vhd` 是第一版 MCU 的纯组合译码器/控制器。

输入：

```text
instr[31:0]
flag_z
flag_n
```

输出给后续 datapath：

```text
cond_ok
illegal_instr
reg_write
mem_read
mem_write
mem_to_reg
flag_write
branch_taken
alu_control
alu_src_imm
ra1
ra2
wa
imm_ext
branch_offset
```

它不包含：

```text
PC
instr_rom
regfile
ALU
data RAM
flags register
```

这些模块需要在顶层 MCU 里另接。

## 2. 支持指令

按最新版指令格式支持：

```text
MOV
ADD
SUB
CMP
LDR
STR
B
BEQ
BNE
MUL
ASR
```

不支持的格式会拉高：

```text
illegal_instr = 1
```

并关闭寄存器、内存、flags、branch 等副作用输出。

## 3. ALU 控制编码

与最新说明文档保持一致：

```text
000 = AND
001 = ORR
010 = ADD
011 = SUB
100 = MUL
101 = ASR
110 = MOV
111 = reserved
```

当前 decoder 实际会输出：

```text
ADD / SUB / MUL / ASR / MOV
```

## 4. 关键语义

条件字段：

```text
1110 = AL
0000 = EQ, flag_z = 1
0001 = NE, flag_z = 0
```

数据处理：

```text
I = 1 -> operand2 使用 zero_extend(imm12)
I = 0 -> operand2 使用 Rm
CMP 只写 flags，不写寄存器
MUL 只支持寄存器型
ASR 只支持立即数型
```

访存：

```text
address = R[Rn] + zero_extend(imm12)
LDR: Rd 是写回目标
STR: Rd 是写内存的数据源，decoder 输出 ra2 = Rd
```

分支：

```text
branch_offset = sign_extend(imm24) << 2
```

顶层 PC 逻辑应使用：

```text
pc_next = branch_taken ? PC + 8 + branch_offset : PC + 4
```

例如当前 FFT 机器码中：

```text
DONE: B DONE
PC = 0x0474
instr = 0xE8FFFFFE
imm24 = -2
branch_offset = -8
PC + 8 - 8 = PC
```

## 5. 本地仿真

已在本机安装并验证：

```bash
brew install ghdl
```

如果 GHDL 被 macOS Gatekeeper 拦截，可以执行一次：

```bash
xattr -dr com.apple.quarantine /opt/homebrew/Caskroom/ghdl/6.0.0/ghdl-llvm-6.0.0-macos15-aarch64
```

运行 testbench：

```bash
ghdl -a --std=08 rtl/mcu_v1_decoder.vhd tb/mcu_v1_decoder_tb.vhd
ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb
```

当前通过结果：

```text
mcu_v1_decoder_tb passed
simulation finished @13ns
```

## 6. Testbench 覆盖

`tb/mcu_v1_decoder_tb.vhd` 当前覆盖：

```text
MOV R8, #0
ADD R12, R12, #4095
LDR R0, [R8 + 4]
STR R0, [R10 + 60]
MUL R11, R11, R12
ASR R11, R11, #15
CMP R1, #0
B DONE
BEQ 条件成立/不成立
BNE 条件成立/不成立
非法 ASR register form
```

这足够先验证 decoder 的字段切分、控制信号和条件分支语义。接下来应把 decoder 接到 regfile、ALU、PC 和 memory，做最小 MCU 顶层联调。
