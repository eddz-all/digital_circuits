# MCU FFT 项目接力记忆

更新时间：2026-06-02

本文档用于在后续会话中快速恢复上下文，继续完成数字电路课程设计中的 8 点 FFT 速度榜任务。

## 下一会话先读这里

当前仓库工作目录：

```text
/Users/eddz/work/Digital_Circuits
```

当前工作分支：

```text
dsp
```

当前最重要状态：

```text
V1 scalar baseline 已完成，用于基础要求和 32-bit fixed reference。
V2 packed DSP 已完成，用于拓展加速要求。
V3 fused DSP 尚未实现，是下一步如果继续提速的方向。
```

完整实验数据汇总文档：

```text
docs/fft8_experiment_results.md
```

当前速度结果：

```text
V1 scalar:
  286 instructions
  276 timed_steps

V2 packed DSP:
  120 instructions
  109 timed_steps
  已达到原目标 timed_steps <= 130
```

当前 GHDL core 仿真数据：

```text
Testbench:
  tb/mcu_v1_core_tb.vhd

V1 scalar FFT:
  MEM_FILE = asm/fft8_v1_mcu32_basic.mem
  x0 impulse 输入:
    x0.real = 32760
    其余 real/imag = 0
  x0 impulse 输出:
    X0..X7 全部 real = 4095, imag = 0

  x1 impulse 输入:
    x1.real = 32760
    其余 real/imag = 0
  x1 impulse 输出槽位:
    slot  0 =  4095
    slot  1 =     0
    slot  2 = -4095
    slot  3 =     0
    slot  4 =     0
    slot  5 = -4095
    slot  6 =     0
    slot  7 =  4095
    slot  8 =  2895
    slot  9 = -2896
    slot 10 = -2896
    slot 11 =  2896
    slot 12 = -2896
    slot 13 = -2896
    slot 14 =  2896
    slot 15 =  2895
  PC:
    0x00000474
  halted_debug:
    1
  illegal_debug:
    0

V2 packed DSP FFT, x0 impulse:
  MEM_FILE = asm/fft8_v2_packed_dsp.mem
  输入:
    x0.real = 32760
    其余 real/imag = 0
  输出:
    X0..X7 全部 real = 4095, imag = 0
  PC:
    0x000001DC
  halted_debug:
    1
  illegal_debug:
    0

V2 packed DSP FFT, x1 impulse:
  输入:
    x1.real = 32760
    其余 real/imag = 0
  输出槽位:
    slot  0 =  4095
    slot  1 =     0
    slot  2 = -4095
    slot  3 =     0
    slot  4 =     0
    slot  5 = -4095
    slot  6 =     0
    slot  7 =  4095
    slot  8 =  2895
    slot  9 = -2896
    slot 10 = -2896
    slot 11 =  2896
    slot 12 = -2896
    slot 13 = -2896
    slot 14 =  2896
    slot 15 =  2895
  PC:
    0x000001DC
  halted_debug:
    1
  illegal_debug:
    0
```

注意速度单位：

```text
脚本里的 timed_steps/cnt_test 不是 PPT 表格里的 万次/秒。
速度 = 时钟频率 / cnt_test
如果按 150 MHz 估算，V2 = 150 MHz / 109 = 137.61 万次/秒。
这已经接近用户截图里的 136.84 万次/秒档位。
```

当前架构判断：

```text
V1/V2 不是双核。
V1/V2 是单核、单周期、单发射 MCU。
tb/mcu_v1_core_tb.vhd 里的 basic_core / fft_core / fast_core 三个实例只是为了 GHDL 同时验证三个程序，不代表最终设计是多核。
```

下一步如果用户说“继续加速”：

```text
不要优先做双核或单核多发射。
建议继续单核、单周期、单发射，做 V3 融合指令。
原因：融合指令最直接降低 cnt_test，也最容易继续用 GHDL 证明。
```

推荐 V3 additive 方案：

```text
新增 asm/fft8_v3_fused_dsp.s，不替换 V1/V2。

优先新增：
  LDCPLX   一条指令读 real/imag 并打包
  STCPLX   一条指令拆 packed real/imag 并写出
  ROTMJ    packed complex 乘 -j
  CMULW1   packed complex 乘 W8^1 = 0.7071 - j0.7071
  CMULW3   packed complex 乘 W8^3 = -0.7071 - j0.7071

目标：
  把 V2 的 109 timed_steps 压到 50-60 timed_steps，接近 PPT 277.78 万次/秒档位。
```

下一会话建议执行顺序：

```text
1. 先看本节和 0.5 / 0.6。
2. 不要切分支，继续在 dsp 分支。
3. 先跑 V1/V2 回归确认基线仍过。
4. 设计 V3 opcode/funct map。
5. 扩展 assembler + host interpreter。
6. 新增 asm/fft8_v3_fused_dsp.s。
7. 扩展 RTL control/data_mem/ALU。
8. 增加 GHDL tests 并跑完整回归。
```

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
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_pkg.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_decoder.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_alu.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_regfile.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_instr_rom.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_input_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_work_ram.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_output_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_data_mem.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_pc_unit.vhd
/Users/eddz/work/Digital_Circuits/rtl/mcu_v1_core.vhd
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_decoder_tb.vhd
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_core_tb.vhd
/Users/eddz/work/Digital_Circuits/docs/mcu_v1_decoder_vhdl.md
/Users/eddz/work/Digital_Circuits/docs/mcu_v1_single_cycle_core.md
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.s
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.mem
/Users/eddz/work/Digital_Circuits/asm/test_mcu_v1_basic.lst
/Users/eddz/work/Digital_Circuits/asm/fft8_v2_packed_dsp.s
/Users/eddz/work/Digital_Circuits/asm/fft8_v2_packed_dsp.mem
/Users/eddz/work/Digital_Circuits/asm/fft8_v2_packed_dsp.lst
/Users/eddz/work/Digital_Circuits/tools/test_fft8_v2_packed_dsp.py
/Users/eddz/work/Digital_Circuits/tb/mcu_v1_alu_tb.vhd
/Users/eddz/work/Digital_Circuits/docs/fft8_v2_packed_dsp.md
/Users/eddz/work/Digital_Circuits/docs/fft8_experiment_results.md
```

## 0.6 2026-06-02 最新讨论与下一会话入口

当前工作分支：

```text
dsp
```

当前状态：

```text
V1 scalar baseline 已完成，保留为基础要求/reference。
V2 packed DSP 加速版已完成，作为拓展要求。
V3 融合指令版尚未实现。
```

用户后续问过“为什么速度还没有截图里的 PPT 排行榜高”。需要记住：截图单位是 `万次/秒`，而当前脚本报告的是 `timed_steps / cnt_test`。二者换算需要乘上时钟频率：

```text
速度 = 时钟频率 / cnt_test
```

如果按常见 `150 MHz` 估算：

```text
V1: 150 MHz / 276 = 54.35 万次/秒
V2: 150 MHz / 109 = 137.61 万次/秒
```

所以 V2 的 `109 timed_steps` 实际已经接近用户截图里的 `136.84 万次/秒` 档位。若要达到：

```text
277.78 万次/秒 -> cnt 约 54
652.27 万次/秒 -> cnt 约 23
```

这意味着下一轮不能只小修小补，需要 V3 把 cycles 从 109 继续压到约 50-60，甚至更低。

重要架构解释：

```text
当前 V1/V2 不是双核。
当前是单核、单周期、单发射 MCU。
tb/mcu_v1_core_tb.vhd 里 basic_core / fft_core / fast_core 三个实例只是为了 GHDL 同时验证不同程序，不是最终设计中的多核。
```

术语解释：

```text
单核单发射：
  一个 core，每个周期最多发射/执行一条指令。
  当前 V1/V2 属于这个类型。

单核多发射：
  一个 core，每个周期可以同时发射多条不冲突的指令。
  理论上能减少 cycles，但需要双取指、双译码、多端口 regfile、多 ALU、访存冲突和数据相关处理。
  对本课设来说复杂度高，不建议优先做。
```

下一步推荐方向：

```text
继续单核、单周期、单发射；
不要优先做双核或多发射；
优先做 V3 融合指令，因为它最容易直接降低 cnt_test，也最容易用 GHDL 证明。
```

推荐 V3 指令方向：

```text
LDCPLX Rd, [Rn + offset]
  从外部 real/imag 相邻 16-bit 槽位读取一个复数并打包到 Rd。
  等价替代 V2 中 LDR real + LDR imag + PKHBT。

STCPLX Rs, [Rn + offset]
  把 packed complex 的 low/high halfword 分别写到外部 real/imag 相邻槽位。
  等价替代 V2 中 STR real + ASR imag + STR imag。

ROTMJ Rd, Rn
  packed complex 乘 -j。
  等价替代 SXTH + ASR #16 + SUB + PKHBT。

CMULW1 Rd, Rn
  packed complex 乘 W8^1 = 0.7071 - j0.7071。
  等价替代 SMUAD + SMUSD + SUB + ASR + ASR + PKHBT。

CMULW3 Rd, Rn
  packed complex 乘 W8^3 = -0.7071 - j0.7071。
  保持 V2 里当前采用的 rounding/shift 顺序。
```

粗略收益估计：

```text
V2 输入打包：16 LDR + 8 PKHBT = 24 条
V3 LDCPLX：8 条
省约 16 cycles

V2 输出拆包：8 STR + 8 ASR + 8 STR = 24 条
V3 STCPLX：8 条
省约 16 cycles

V2 旋转序列：W1/W3/-j 都是多条固定模板
V3 ROTMJ/CMULW1/CMULW3 可再省约 20+ cycles
```

因此 V3 有希望从：

```text
V2: 109 timed_steps
```

压到：

```text
V3 target: 50-60 timed_steps
```

这样才可能接近用户截图中的 `277.78 万次/秒` 档位。

实现提醒：

```text
LDCPLX / STCPLX 想保持单周期，需要扩展 mcu_v1_data_mem / input_mem / output_mem 的相邻槽位双读或双写能力。
这不等于多发射，仍然是一条指令一个周期，只是这条指令内部做了更宽的 memory 操作。
V3 应该 additive：新增 asm/fft8_v3_fused_dsp.s，不替换或删除 V1/V2。
```

下一会话如果用户说“继续做 V3”，建议先做：

```text
1. 设计 V3 opcode/funct map，保留现有 V1/V2 编码。
2. 扩展 assembler + host interpreter。
3. 新增 asm/fft8_v3_fused_dsp.s。
4. 扩展 RTL control/data_mem 支持 LDCPLX/STCPLX 和 fused rotate。
5. 增加 ALU/data_mem/decoder/core GHDL tests。
6. 跑完整 regression。
```

## 0.5 2026-06-02 DSP 分支 packed FFT 加速进展

用户要求不要直接改基础版电路，而是在 `dsp` 分支实现拓展加速版。当前已在 `dsp` 分支新增 packed DSP 扩展，V1 scalar baseline 仍保留。

新增指令类：

```text
op[27:26] = 11
funct[25:21]
reserved[20] = 0

00000 = SHADD16
00001 = SHSUB16
00010 = SMUAD
00011 = SMUSD
00100 = SXTH
00101 = PKHBT
```

新增 fast FFT：

```text
asm/fft8_v2_packed_dsp.s
asm/fft8_v2_packed_dsp.mem
asm/fft8_v2_packed_dsp.lst
tools/test_fft8_v2_packed_dsp.py
docs/fft8_v2_packed_dsp.md
```

当前 V2 指标：

```text
120 条指令
119 条执行指令 before DONE self-loop
109 条 timed steps
目标 timed_steps <= 130 已达到
V1 baseline timed_steps = 276
```

数值验证口径：

```text
常见边界样例 + 1000 组中等幅度随机输入：精确匹配 V1 scalar fixed model
5000 组完整 16-bit 随机输入：精确匹配 packed DSP fixed model
```

完整 16-bit 随机输入不强制匹配 V1 scalar，是因为 packed halfword 旋转中间值可能超过 signed 16-bit lane，V2 会按 halfword lane 语义截断；V1 scalar baseline 会保留 32-bit 中间值。答辩时建议把 V1 作为准确 reference，把 V2 作为 packed DSP 加速拓展展示。

当前新增 GHDL 覆盖：

```text
tb/mcu_v1_alu_tb.vhd
  SHADD16 / SHSUB16 / SMUAD / SMUSD / SXTH / PKHBT

tb/mcu_v1_decoder_tb.vhd
  新增 DSP opcode decode 与非法扩展格式检查

tb/mcu_v1_core_tb.vhd
  fast_core 加载 asm/fft8_v2_packed_dsp.mem
  x0 impulse -> 全部 real=4095, imag=0
  x1 impulse -> bit-reversal spectrum
```

当前 GHDL core 仿真数据：

```text
V1 scalar FFT:
  asm/fft8_v1_mcu32_basic.mem
  input:  x0.real=32760, others=0
  output: X0..X7 all real=4095, imag=0
  x1 impulse output slots:
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
  pc_debug=0x00000474
  halted_debug=1
  illegal_debug=0

V2 packed DSP FFT:
  asm/fft8_v2_packed_dsp.mem
  x0 impulse output: X0..X7 all real=4095, imag=0
  x0 pc_debug=0x000001DC, halted_debug=1, illegal_debug=0

  x1 impulse output slots:
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
  x1 pc_debug=0x000001DC, halted_debug=1, illegal_debug=0
```

## 0.4 2026-06-02 VHDL 模块化进展

为便于讲解，当前 RTL 已进一步模块化。

新增：

```text
rtl/mcu_v1_pkg.vhd
rtl/mcu_v1_input_mem.vhd
rtl/mcu_v1_work_ram.vhd
rtl/mcu_v1_output_mem.vhd
rtl/mcu_v1_pc_unit.vhd
```

当前模块职责：

```text
mcu_v1_pkg        公共常量：ALU 控制码、opcode、条件码、地址区域码
mcu_v1_decoder    指令译码和控制信号
mcu_v1_regfile    16 个 32-bit 寄存器
mcu_v1_alu        AND / ORR / ADD / SUB / MUL / ASR / MOV；dsp 分支还支持 packed DSP 操作
mcu_v1_instr_rom  指令 ROM，读取 .mem
mcu_v1_pc_unit    PC+4、PC+8+branch_offset、自循环 halted 检测
mcu_v1_data_mem   数据地址区路由
mcu_v1_input_mem  输入区，模拟 test_ROM，16-bit signed -> 32-bit signed
mcu_v1_work_ram   工作区，32-bit RAM
mcu_v1_output_mem 输出区，模拟 verify_RAM，写入低 16-bit
mcu_v1_core       顶层连线
```

新的 GHDL 编译顺序：

```text
ghdl -a --std=08 \
  rtl/mcu_v1_pkg.vhd \
  rtl/mcu_v1_decoder.vhd \
  rtl/mcu_v1_alu.vhd \
  rtl/mcu_v1_regfile.vhd \
  rtl/mcu_v1_instr_rom.vhd \
  rtl/mcu_v1_input_mem.vhd \
  rtl/mcu_v1_work_ram.vhd \
  rtl/mcu_v1_output_mem.vhd \
  rtl/mcu_v1_data_mem.vhd \
  rtl/mcu_v1_pc_unit.vhd \
  rtl/mcu_v1_core.vhd \
  tb/mcu_v1_alu_tb.vhd \
  tb/mcu_v1_decoder_tb.vhd \
  tb/mcu_v1_core_tb.vhd
```

## 0.3 2026-06-02 指令集完善进展

根据 `数字电路实验_MCU.pptx` 第 3 页最低要求，MCU 至少需要支持：

```text
ADD / SUB / AND / OR / MOV / LDR / STR / B/BL
```

当前 GHDL baseline 已补齐：

```text
AND
ORR   ; PPT 写 OR，ARM mnemonic 使用 ORR；汇编器同时接受 OR 作为别名
BL
```

当前正式支持指令变为：

```text
MOV / ADD / SUB / AND / ORR / CMP / LDR / STR / B / BL / BEQ / BNE / MUL / ASR
```

BL 编码沿用当前分支类格式：

```text
op[27:26] = 10
bit25     = 0
bit24     = L
L = 0: B / BEQ / BNE
L = 1: BL
branch target = PC + 8 + (sign_extend(imm24) << 2)
BL link write = R14 = PC + 4
```

已修改：

```text
tools/assemble_mcu_v1.py
rtl/mcu_v1_decoder.vhd
rtl/mcu_v1_core.vhd
tb/mcu_v1_decoder_tb.vhd
tb/mcu_v1_core_tb.vhd
asm/test_mcu_v1_basic.s
asm/test_mcu_v1_basic.mem
asm/test_mcu_v1_basic.lst
docs/member2_mcu_isa_plan.md
docs/mcu_v1_decoder_vhdl.md
docs/mcu_v1_single_cycle_core.md
```

新增基础程序检查：

```text
AND R6, R6, R7   ; 10 AND 12 = 8
ORR R7, R6, #3   ; 8 OR 3 = 11
BL AFTER_BL      ; R14 = 0x0074
```

最新验证：

```text
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/assemble_mcu_v1.py asm/fft8_v1_mcu32_basic.s
python3 tools/assemble_mcu_v1.py asm/test_mcu_v1_basic.s
ghdl -a/e/r mcu_v1_decoder_tb
ghdl -a/e/r mcu_v1_core_tb
```

结果：

```text
FFT 对拍通过
fft8_v1_mcu32_basic.s: 286 instructions, DONE PC 0x0474
test_mcu_v1_basic.s:   36 instructions, DONE PC 0x008C
mcu_v1_decoder_tb passed
mcu_v1_core_tb passed
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

第一版不要依赖：

```text
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
R13        预留
R14        BL 链接寄存器
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
正式支持 MOV/ADD/SUB/AND/ORR/CMP/LDR/STR/B/BL/BEQ/BNE/MUL/ASR
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
不使用 BL（MCU 已支持 BL，但 FFT 主程序不需要函数调用）
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
