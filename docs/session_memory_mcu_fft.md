# MCU FFT 项目接力记忆

更新时间：2026-06-02

本文档用于在后续会话中快速恢复上下文，继续完成数字电路课程设计中的 8 点 FFT 速度榜任务。

## 0. 2026-06-02 最新接口覆盖说明

2026-06-02 用户补充两份最新要求：

```text
/Users/eddz/Library/Containers/com.tencent.qq/Data/Downloads/第一版MCU指令格式说明.md
/Users/eddz/Library/Containers/com.tencent.qq/Data/Downloads/第一版MCU对成员A接口说明.md
```

这些要求覆盖本文档中旧的 `0x1000 / 0x2000` 基址和输入/输出 `+2` 步长口径。

最新第一版接口应以以下内容为准：

```text
INPUT_BASE   = 0x00000000
WORK_BASE    = 0x00000100
OUTPUT_BASE  = 0x00000200
```

程序员视角下：

```text
输入区、工作区、输出区统一按 32-bit 槽位访问
三个区域相邻槽位地址步长统一为 +4
输入区 LDR：底层 16-bit signed -> 寄存器 32-bit signed
输出区 STR：寄存器 32-bit -> 外部 16-bit verify_RAM
```

最新指令格式还规定数据处理和访存立即数为 `imm12`，所以单条立即数不能超过 `4095`。因此 `23170` 不能再写成：

```asm
MOV R12, #23170
```

当前应使用多条 `imm12` 安全指令构造：

```asm
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
```

最新代码文件：

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.s
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.mem
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.lst
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v1_mcu32_basic.py
/Users/eddz/work/Digital_Circuits/tools/assemble_mcu_v1.py
/Users/eddz/work/Digital_Circuits/docs/fft8_v1_mcu32_check_rules.md
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_decoder.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_alu.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_regfile.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_instr_rom.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_data_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_core.vhd
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_decoder_tb.vhd
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_core_tb.vhd
/Users/eddz/work/Digital_Circuits/docs/mcu_v1_decoder_vhdl.md
/Users/eddz/work/Digital_Circuits/docs/mcu_v1_single_cycle_core.md
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.s
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.mem
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.lst
```

## 1. 当前任务

用户是三人小组中的成员 1，负责：

```text
FFT 算法与汇编优化
```

核心目标：

```text
在自研 MCU 上，用汇编程序完成 8 点复数 FFT，并尽可能减少 cnt_test 周期。
```

当前优先级：

```text
1. 先写第一版 MCU 可执行的 FFT 汇编
2. 保证符合成员 2 当前承诺的第一版 MCU 接口
3. 先正确跑通，再逐步优化速度
```

## 2. 板卡、芯片与“内核”结论

课程使用的不是现成 ARM Cortex-M MCU。

实际平台是：

```text
K7EDA-EVAL FPGA 开发板
Xilinx Kintex-7 FPGA
芯片：XC7K160T-2FFG676-I
Vivado part：xc7k160tffg676-2
```

重要结论：

```text
这块板没有硬 ARM Cortex 内核。
需要在 Kintex-7 FPGA 上自己设计一个 ARM-like 软 MCU。
```

因此：

```text
指令快慢不由 Cortex-M3/M4/M7 决定，
而由成员 2 设计的 MCU 微架构决定。
```

课程要求中提到：

```text
MCU 只能执行 ARM 指令集范围内的指令，不允许额外扩展指令。
MCU 微架构不限，可流水、并行、单指令多操作等优化。
```

但第一版先不追复杂优化。

## 3. 课程 FFT 任务要求

来自 `数字电路实验_MCU.pptx` 第 10-12 页。

FFT 任务要求：

```text
设计一个程序，在所设计 MCU 上完成 8 点 FFT 变换。
全部设计必须以 MCU 指令形式完成，不能做专用硬件芯片。
最后要求展示对应汇编指令。
```

输入输出：

```text
输入来自外部 test_ROM
输入线路名：test_vector_in
输入包含 8 个采样点，每个采样点包含实部和虚部
输入数据：16-bit 定点数

输出写入外部 verify_RAM
输出线路名：verify_vector_out
输出数据：16-bit 定点数
```

计时：

```text
从第一个数据读入开始，cnt_test 开始计数。
最后一个数据输出完成后停止计数。
最后时间 = cnt_test 计数 × 时钟周期。
```

验收：

```text
以上板结果为准，不以 simulation 结果为准。
Timing report 必须无 violation，WNS 必须为正。
```

## 4. 当前最新 MCU 接口

最新接口来自：

```text
/Users/eddz/Documents/Obsidian Vault/第一版MCU对成员A接口说明.md
```

当前第一版 MCU 约定如下。

### 4.1 总体宽度

```text
指令宽度：32-bit
地址宽度：32-bit
内部通用寄存器数量：16
内部通用寄存器宽度：32-bit
内部计算宽度：32-bit
寻址方式：统一字节寻址
```

注意：

```text
外部输入数据仍然是 16-bit signed
外部输出数据仍然是 16-bit signed
但 MCU 程序看到和处理的数据按 32-bit signed 理解
```

也就是：

```text
外部世界：16-bit
MCU 内部程序世界：32-bit
```

### 4.2 地址空间

第一版程序统一使用三个基址：

```text
INPUT_BASE   = 0x00000000
WORK_BASE    = 0x00000100
OUTPUT_BASE  = 0x00000200
```

含义：

```text
INPUT_BASE   对应外部 test_ROM
WORK_BASE    对应 MCU 内部工作 RAM
OUTPUT_BASE  对应外部 verify_RAM
```

成员 1 写程序时只需要按这三个基址写，不需要关心底层如何连接外部存储器。

### 4.3 数据访问规则

输入区：

```text
外部是 16-bit signed
程序视角输入槽位步长：+4
LDR 从输入区读到寄存器后，值已经是 32-bit signed
```

例子：

```asm
LDR R0, [R8 + 0]
LDR R1, [R8 + 4]
LDR R2, [R8 + 8]
```

工作区：

```text
内部工作 RAM 是 32-bit
工作区地址步长：+4
LDR/STR 读写 32-bit 数据
```

例子：

```asm
STR R0, [R9 + 0]
STR R1, [R9 + 4]
LDR R2, [R9 + 0]
```

输出区：

```text
外部 verify_RAM 按 16-bit 样本组织
程序视角输出槽位步长：+4
程序用 STR 写出 32-bit 结果
底层负责转换成外部需要的 16-bit
```

例子：

```asm
STR R0, [R10 + 0]
STR R1, [R10 + 4]
```

### 4.4 当前正式支持指令

第一版正式支持：

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

第一版不要依赖：

```text
BL
BX
函数调用
栈
MLA
packed DSP 指令
批量访存
```

因此第一版 FFT 程序应写成：

```text
直线展开代码
少量或不用循环
不用函数调用
不用栈
不用 DSP packed 指令
```

### 4.5 推荐寄存器用途

```text
R0 ~ R7    当前运算数据与中间变量
R8         输入区基址或输入指针
R9         工作区基址或工作指针
R10        输出区基址或输出指针
R11        循环计数器或偏移
R12        常量寄存器，例如 23170
R13 ~ R14  预留
R15        不作为普通寄存器使用
```

## 5. 当前算法决策

第一版 FFT 建议：

```text
8 点复数正向 FFT
radix-2 DIF
完全展开
real/imag 分开
内部 32-bit signed 计算
每级蝶形后除以 2
最终输出 = FFT(input) / 8
```

为什么每级除以 2：

```text
虽然内部是 32-bit，但 MUL 只返回 32-bit。
如果完全不缩放，旋转因子乘法前的中间值可能增大，存在溢出风险。
每级 ASR #1 缩放能保证安全，也便于输出到 16-bit。
```

旋转因子：

```text
W8^0 = 1
W8^1 =  0.7071 - j0.7071
W8^2 = -j
W8^3 = -0.7071 - j0.7071
```

Q15 常数：

```text
0.70710678 -> 23170
```

乘 0.7071 的写法。注意最新版指令格式是 `imm12`，不能单条 `MOV #23170`：

```asm
MOV R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #4095
ADD R12, R12, #2695
MUL R4, R0, R12
ASR R4, R4, #15
```

含义：

```text
R4 = R0 * 23170 / 32768
   ≈ R0 * 0.70710678
```

输出顺序：

```text
DIF 最快自然输出是 bit-reversal：
X0, X4, X2, X6, X1, X5, X3, X7
```

如果验收要求自然序，只需调整最后写 OUTPUT_BASE 的顺序。

## 6. 已经创建的项目文件

项目目录：

```text
/Users/eddz/work/Digital_Circuits
```

已经创建的重要文件：

```text
/Users/eddz/work/Digital_Circuits/docs/member2_mcu_isa_plan.md
```

说明：

```text
给成员 2 的第一版 MCU 指令集方案。
已按 2026-06-02 最新接口修订：
基址 0x000 / 0x100 / 0x200，三个区域程序视角统一 +4 槽位步长，立即数遵守 imm12。
```

```text
/Users/eddz/work/Digital_Circuits/docs/fft8_arm_assembly_explained.md
```

说明：

```text
解释之前 ARMv7E-M DSP packed 版本的文档。
目前只作为第二版优化参考，不适合作为第一版 MCU 程序。
```

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_dif_q15_armv7em.s
```

说明：

```text
高速 ARMv7E-M DSP 指令版。
使用 SHADD16/SHSUB16/SMUAD/SMUSD/PKHBT 等。
第一版 MCU 不能直接跑，只作为后续优化参考。
```

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_basic_scalar_arm_pseudo.s
```

说明：

```text
早期基础标量草案。
它不完全匹配当前最新接口，也依赖宏和旧写法。
当前第一版应使用 fft8_v1_mcu32_basic.s。
```

```text
/Users/eddz/work/Digital_Circuits/tools/test_fft8_dif_q15.py
```

说明：

```text
用于验证旧 packed DSP 版本算法。
旧 packed DSP 版本对拍脚本。
当前第一版 MCU32 标量版本应使用 tools/test_fft8_v1_mcu32_basic.py。
```

## 7. 下一步详细计划

### 第一步：修订成员 2 指令集文档

文件：

```text
/Users/eddz/work/Digital_Circuits/docs/member2_mcu_isa_plan.md
```

状态：

```text
已完成。
已按最新接口修订为：
INPUT_BASE / WORK_BASE / OUTPUT_BASE = 0x000 / 0x100 / 0x200
输入区、工作区、输出区程序视角统一 +4
不依赖 BX / MLA
正式支持 MOV/ADD/SUB/CMP/LDR/STR/B/BEQ/BNE/MUL/ASR
```

### 第二步：编写第一版真正兼容接口的 FFT 汇编

文件：

```text
/Users/eddz/work/Digital_Circuits/asm/fft8_v1_mcu32_basic.s
```

要求：

```text
只使用 MOV/ADD/SUB/CMP/LDR/STR/B/BEQ/BNE/MUL/ASR
不使用 BX
不使用 BL
不使用 MLA
不使用 LDM/STM
不使用 SHADD16/SHSUB16/SMUAD/SMUSD
```

数据格式：

```text
输入区：
  base + 0   x0.real  16-bit signed，LDR 后为 32-bit signed
  base + 4   x0.imag
  base + 8   x1.real
  base + 12  x1.imag
  ...

工作区：
  base + 0   临时 32-bit 数据
  base + 4   临时 32-bit 数据
  ...

输出区：
  base + 0   输出第 1 个 16-bit signed
  base + 4   输出第 2 个 16-bit signed
  ...
```

程序形态：

```text
完全展开 8 点 DIF FFT
每级用 ADD/SUB 后 ASR #1
乘 0.7071 用 MUL + ASR #15
最终写出 bit-reversal 顺序，或根据验收要求改自然序
```

状态：

```text
已完成。
当前版本使用最新基址和 +4 槽位步长。
23170 已拆成多条 imm12 安全指令构造。
```

### 第三步：新写 host-side 对拍脚本

文件：

```text
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v1_mcu32_basic.py
```

脚本应模拟：

```text
输入外部 16-bit signed
LDR 后变成 32-bit signed
内部 32-bit 计算
每级缩放 /2
输出 FFT/8
输出转换成 16-bit signed
bit-reversal 输出顺序
```

用途：

```text
给成员 3 生成对拍样例
验证汇编算法是否正确
```

状态：

```text
已完成。
脚本会直接解释执行 asm/fft8_v1_mcu32_basic.s，并检查指令白名单、imm12、地址区和定点结果。
```

补充编码级检查：

```text
tools/assemble_mcu_v1.py 会按最新版机器码格式编码 asm/fft8_v1_mcu32_basic.s。
已生成 asm/fft8_v1_mcu32_basic.mem 和 asm/fft8_v1_mcu32_basic.lst。
当前 DONE: B DONE 位于 PC 0x0474，机器码为 0xE8FFFFFE，对应 PC+8 规则下 imm24 = -2。
```

最新验证规模：

```text
python3 tools/test_fft8_v1_mcu32_basic.py
  7 组边界/极值样例通过
  1000 组中等幅度随机样例通过
  5000 组完整 16-bit 范围随机样例通过

python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
  286 条指令全部可编码
  DONE 自循环编码为 0xE8FFFFFE
```

## 0.1 2026-06-02 VHDL decoder 进展

已新增第一版 MCU 纯组合译码器：

```text
rtl/mcu_v1_decoder.vhd
```

对应 testbench：

```text
tb/mcu_v1_decoder_tb.vhd
```

说明文档：

```text
docs/mcu_v1_decoder_vhdl.md
```

decoder 支持：

```text
MOV / ADD / SUB / CMP / LDR / STR / B / BEQ / BNE / MUL / ASR
```

关键语义：

```text
cond: AL / EQ / NE
imm12: zero extend
imm24: sign_extend 后左移 2
branch_offset = sign_extend(imm24) << 2
顶层 PC 逻辑需要 pc_next = branch_taken ? PC + 8 + branch_offset : PC + 4
STR 使用 Rd 作为写内存数据源，即 decoder 输出 ra2 = Rd
CMP 只写 flags，不写寄存器
MUL 只支持寄存器型
ASR 只支持立即数型
```

本机已安装 GHDL，并通过仿真：

```text
ghdl -a --std=08 rtl/mcu_v1_decoder.vhd tb/mcu_v1_decoder_tb.vhd
ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb

结果：
mcu_v1_decoder_tb passed
simulation finished @13ns
```

## 0.2 2026-06-02 单周期 MCU baseline 进展

已新增最小单周期 MCU core：

```text
rtl/mcu_v1_alu.vhd
rtl/mcu_v1_regfile.vhd
rtl/mcu_v1_instr_rom.vhd
rtl/mcu_v1_data_mem.vhd
rtl/mcu_v1_core.vhd
```

对应 testbench：

```text
tb/mcu_v1_core_tb.vhd
```

说明文档：

```text
docs/mcu_v1_single_cycle_core.md
```

基础小测试程序：

```text
asm/test_mcu_v1_basic.s
asm/test_mcu_v1_basic.mem
asm/test_mcu_v1_basic.lst
```

当前 core 结构：

```text
PC -> instr_rom(组合读) -> decoder -> regfile(组合读/同步写)
   -> ALU -> data_mem(组合读/同步写) -> writeback -> PC update
```

支持：

```text
MOV / ADD / SUB / CMP / LDR / STR / B / BEQ / BNE / MUL / ASR
```

本机已通过 GHDL 仿真：

```text
ghdl -a --std=08 rtl/mcu_v1_decoder.vhd rtl/mcu_v1_alu.vhd rtl/mcu_v1_regfile.vhd rtl/mcu_v1_instr_rom.vhd rtl/mcu_v1_data_mem.vhd rtl/mcu_v1_core.vhd tb/mcu_v1_decoder_tb.vhd tb/mcu_v1_core_tb.vhd
ghdl -e --std=08 mcu_v1_decoder_tb
ghdl -r --std=08 mcu_v1_decoder_tb
ghdl -e --std=08 mcu_v1_core_tb
ghdl -r --std=08 mcu_v1_core_tb

结果：
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
```

`mcu_v1_core_tb` 做了两类验证：

```text
1. 加载 asm/test_mcu_v1_basic.mem：
   输入 slot0=1000, slot1=-500
   输出 slot0=500, slot1=1500, slot2=707, slot3=123

2. 加载 asm/fft8_v1_mcu32_basic.mem：
   输入 x0.real=32760，其余为 0
   输出 8 个复数均为 real=4095, imag=0
   PC 停在 0x0474，halted_debug=1，illegal_debug=0
```

注意：

```text
当前 baseline 使用组合读 instr_rom / data_mem，适合功能仿真和小规模 distributed memory。
如果 Vivado 推成同步 BRAM，则严格单周期取指/LDR 会不成立，需要改多周期或指定 distributed memory。
```

### 第四步：整理给成员 3 的对拍规则

需要说明：

```text
正向 FFT
输出 = FFT/8
输出顺序默认 bit-reversal：X0, X4, X2, X6, X1, X5, X3, X7
输入/输出均按 real, imag, real, imag 排列
外部数据为 16-bit signed
```

状态：

```text
已完成。
见 docs/fft8_v1_mcu32_check_rules.md
```

## 8. 注意事项

1. 当前项目已经是 git 仓库。
2. 当前 baseline 已提交：

```text
commit 7f6b62e
message: baselne
branch: master
```

3. 旧 ARMv7E-M DSP 汇编只是第二版速度优化参考，不是当前第一版 MCU 目标。
4. 第一版 MCU 当前没有 `BX`，所以汇编末尾不要写 `BX LR`。当前程序使用：

```asm
DONE:
    B DONE
```

5. `DONE: B DONE` 在当前机器码中编码为 `0xE8FFFFFE`，对应 `PC + 8` 分支规则下的自循环。
6. `MUL` 必须按 signed 32-bit 乘法理解；`ASR` 必须是算术右移，不能用逻辑右移。
7. 当前单周期 core 是功能仿真 baseline：组合读 `instr_rom` / `data_mem`。Vivado 综合上板前要关注 ROM/RAM 是否被推成同步 BRAM。
8. 第一版不要追求 packed 16-bit，也不要上来用 DSP 指令。先跑通。

## 9. 当前一句话总结

当前状态：

```text
已经完成 first baseline：
1. 最新接口下的 8 点 FFT 汇编与机器码。
2. VHDL decoder。
3. 最小单周期 MCU core。
4. GHDL 功能仿真通过。
5. git commit: 7f6b62e baselne。
```

下一个对话建议从这里继续：

```text
1. 在 Vivado 中创建仿真工程，加入 rtl/*.vhd、tb/*.vhd 和 asm/*.mem。
2. 先跑 mcu_v1_decoder_tb。
3. 再跑 mcu_v1_core_tb。
4. 如果 Vivado 找不到 .mem，处理仿真工作目录或改 MEM_FILE 路径。
5. 仿真通过后，再决定是否做 Vivado-friendly ROM/RAM 或上板综合版本。
```
