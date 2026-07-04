# MCU 协同开发总约束

本文档给协同开发者统一开发边界，综合来源包括课程 PPT、老师聊天确认以及
`docs/MCU_GENERALITY_REQUIREMENTS.md`。如果 PPT 与老师后续聊天记录存在冲突，
以聊天记录为准。

核心结论：

```text
我们做的是通用 MCU。FFT、基础指令测试、未来排序程序都应该是 ROM 里的程序。
不能把 FFT 或某一套固定指令序列做成隐藏在 RTL 里的专用硬件。
```

## 0. 协作者改动前红线

如果只是读代码，可以跳过本节；如果要改 RTL、IP 配置、汇编或上板 wrapper，必须先检查这些
红线。下面任何一条被改动，都需要重新说明理由、跑完仿真和 Vivado 报告，再提交。

必须保持：

- FFT 计算只能来自 ROM 中可见的 32-bit 指令序列，不能来自固定 PC、固定 stage、
  hidden butterfly 或 hidden twiddle 状态机。
- `mcu4_multicycle_core` 保持通用 MCU core 集群，只暴露 `dmem_*` 数据内存口；
  FFT 的输入装载、bit-reversal、16/32-bit 打包拆包和输出 dump 只属于 `mcu_fft_system`
  或更外层 wrapper。
- `cnt_start/cnt_stop` 计数边界不能为了降低成绩随意移动。当前性能口径是输入预装完成后，
  从第一条 worker 指令读取开始计数，到所有 active worker 最后一条指令完成或 halt 后停止。
- FFT 性能版 ILA 保持 4 个 probe：`test_vector_in`、`cnt_test`、`verify_ram_addr`、
  `verify_vector_out`。不要在性能 bitstream 里恢复宽 debug trace 或 `verify_RAM`
  回读 FSM；临时调试请另建 debug run/top。
- `pair_kind` 这类 ROM-local predecode 只能来自相邻真实指令的 opcode/寄存器/访存条件；
  不允许来自固定 PC 表。对外端口保持 3-bit `std_logic_vector` 编码，避免 Vivado 对
  自定义 package enum 端口的解析问题。
- `PROGRAM_ID` 只能选择 ROM 程序，`ACTIVE_CORES` 只能选择启用核数；二者不能改变 ISA
  或单条指令语义。
- DSP48 使用量必须为 0。`SMUAD/SMUSD` 是 ARM-DSP 风格指令，不等于允许映射 FPGA DSP。

改动后最低检查：

```text
GHDL: worker_min_arm, multicycle_min_arm, multicycle_core, mcu_fft_system, board_top, board_top_basic_test
Vivado: 目标频率下 WNS/WHS >= 0，DSP = 0，top/IP/probe 宽度与本文档一致
```

当前 170 MHz 性能基线已经过时序，`mcu_fft_system_tb` 的计数窗口应保持 `cnt_cycles = 22`。
如果提交导致 `cnt`、输出结果、ILA probe 数量、DSP 数量或 170 MHz WNS 变差，提交说明里必须
明确写出原因和新的验证结果。

## 1. 总体定位

本工程当前位于 `MCU_4cores_muticycle`，目标是一个四核、多周期、支持 ARM/ARM-DSP
风格指令的 MCU。现在 ROM 里恰好放了 FFT 程序，并额外放了基础指令自测程序。

允许的说法：

```text
四个 worker core 各自取 32-bit 指令、译码、访问寄存器堆和工作内存；
FFT butterfly 由可见的 ARM/ARM-DSP 指令序列完成；
更换 ROM 程序后，同一个 core 仍按同一套取指、译码、执行、访存、写回流程运行。
```

禁止的说法：

```text
RTL 看到某个 PC 范围后自动执行 FFT stage；
某几条 FFT 指令自动合并成一个不可见 butterfly；
PROGRAM_ID 改变了 core 的指令语义；
ACTIVE_CORES 改变了单个 core 的 ISA。
```

## 2. PPT 硬性要求

课程 PPT 对 MCU 的基本要求：

- 至少支持 `ADD`、`SUB`、`AND`、`OR/ORR`、`MOV`、`LDR`、`STR`、`B/BL`。
- 可以在 ARM 指令集范围内扩展更多指令。
- MCU 结构不限制，可以使用流水、超流水、单指令多操作、硬件加速核、多核并行等方法。
- 但全部应用必须以 MCU 指令形式完成，不能做专用硬件芯片。
- 验收会看上板结果，不以仿真结果替代现场结果。
- timing report 必须满足时序，WNS 不能为负。
- 性能时间按 `cnt` 计数乘以时钟周期计算。
- 资源效率按 `6 * LUT + 10 * FF` 这类口径统计，DSP 资源另见第 9 节。

PPT 中排序与 FFT 都要求展示对应汇编指令。即使我们当前主攻 FFT，架构也必须能解释为
通用 MCU，而不是 FFT 专用芯片。

## 3. 老师聊天确认

聊天记录中有三个关键修正，开发时必须遵守：

1. FFT/DFT 具体算法不限制，只要求计算结果正确。
2. 外部 `test_ROM` 到 MCU 内部内存、内部结果到 `verify_RAM` 的交互，不一定要由 MCU
   指令逐条搬运，可以由测试平台/外层控制器完成。
3. `cnt` 计数边界以聊天记录为准：从指令存储器第一条指令读取开始，到指令存储器中
   最后一条指令执行完成结束。

这意味着当前 `mcu_fft_system` 先装载输入、再释放 core 开始计数、core halt 后停止计数、
最后回写 `verify_RAM` 的思路是允许的。输入加载和输出 dump 可以属于测试平台，不必计入
core 指令执行窗口。

## 4. 当前工程必须保持的 MCU 元件

每个 active worker core 必须保持这些通用 MCU 结构：

```text
PC
32-bit instruction ROM
instruction/debug word
decoder 或 ROM-local predecode
register file r0-r15
ALU
LDR/STR 访存路径
ARM-DSP 风格多周期执行路径
halt / illegal 状态
```

当前顶层关系：

```text
board_top
  -> mcu_fft_system          外层测试平台/板级包装
    -> mcu4_multicycle_core  四核 MCU 与工作内存
      -> mcu4_worker_core    单个 worker 执行核心
      -> mcu4_worker_instr_rom
```

`board_top` 和 `mcu_fft_system` 可以为上板、ILA、输入输出搬运服务；真正的计算逻辑必须在
worker 执行 ROM 指令时完成。

## 5. 指令与程序 ROM 约束

当前权威机器码位置：

```text
rtl/mcu4_worker_instr_rom.vhd
```

其中必须显式保存 32-bit 指令常量：

```text
FFT_ROM_W0..FFT_ROM_W3  -- 四个 FFT worker 的程序
SELFTEST_ROM            -- 基础指令测试程序
```

要求：

- ROM 中要能直接看到 32-bit 指令字。
- `asm/` 下保留可读汇编清单，用于验收讲解。
- 不允许在 RTL 中用函数“生成”整套程序来掩盖指令内容。
- `instr_debug` 应表示真实 ROM 指令字，不能伪造成解释性标签。
- 新增程序时，应新增显式 ROM 常量和汇编清单，而不是改执行单元识别某种算法。

当前推荐参数：

```text
PROGRAM_ID = 0, ACTIVE_CORES = 4  -- 四核 FFT 程序
PROGRAM_ID = 1, ACTIVE_CORES = 1  -- 基础指令/PPT 自测程序
```

`PROGRAM_ID` 只选择程序，`ACTIVE_CORES` 只选择启用几个 worker。二者都不应该改变某条指令
本身的语义。

## 6. 命名风格与抽象层级

命名必须服务“通用 MCU”这个口径。不要让代码、注释或文档看起来像 FFT 专用数据通路。

### 程序与答辩口径

汇编清单、学习文档和答辩说明中，基础指令测试应按普通 MCU 数据内存来讲：

```asm
LDR r8, [r0, #0x40]
STR r9, [r0, #0x44]
```

可以把这些地址解释成：

```text
data[0]  byte address 0x40
data[1]  byte address 0x44
data[2]  byte address 0x48
data[3]  byte address 0x4C
data[4]  byte address 0x50
data[5]  byte address 0x54
data[6]  byte address 0x58
data[7]  byte address 0x5C
```

基础测试不应该在程序注释里写成 `LDR [bank0+0]`、`STR [bank1+0]` 这类实现口径。`bank0/bank1`
是 RTL 内部存储组织，不是指令格式。

### RTL 内部口径

RTL 里允许使用：

```text
dmem_bank0
dmem_bank1
DMEM_BANK0_BASE_WORD
DMEM_BANK1_BASE_WORD
dmem_bank_t
WOP_LDR_BANK0 / WOP_STR_BANK0
WOP_LDR_BANK1 / WOP_STR_BANK1
```

含义是“data memory bank 0/1”，也可以对外解释成一块数据内存里的两个地址区域。
这些名字只描述存储实现和译码后的内部端口，不表示有 FFT 专用 buffer。

### 禁止回退的旧命名

新代码、注释和文档中不要再引入：

```text
buf_a / buf_b
WORK_BUF_A_BASE_WORD / WORK_BUF_B_BASE_WORD
complex8_array_t
WOP_LDR_A / WOP_STR_B
```

`buf_a/buf_b` 容易被理解成 FFT ping-pong buffer。当前统一写成 `dmem_bank0/dmem_bank1`。
如果写给非 RTL 读者看，优先写成 `data[n]` 或“数据内存地址”。

### 寄存器命名

公共 package 里只保留通用寄存器编号：

```text
REG_R0..REG_R15
REG_LR
REG_PC
```

不要在公共 RTL/package 中恢复 `REG_POS91`、`REG_TMP_RE`、`REG_EVEN` 这类 FFT 程序变量名。
如果某个程序临时把 `r1` 用作 `+91`，只应写在该程序的汇编注释里，不能让硬件寄存器命名变成 FFT 专用。

### LDR/STR 地址边界说明

当前工程支持 ARM-like 的 `LDR/STR` 立即数地址形式，并由 decoder 把固定地址窗口映射到内部
data memory bank。展示时可以说“普通 `LDR/STR` 访问数据地址”；但不要夸大成完整 ARM
任意基址寄存器、任意偏移的大数据 RAM。

一句话：

```text
程序视角是 data memory address；RTL 视角是 dmem_bank0/dmem_bank1；禁止再用 FFT buffer 命名。
```

## 7. 允许的优化

允许做大胆的速度优化，资源可以适当放开，但优化依据必须来自通用指令属性、寄存器依赖和
访存端口约束，而不是来自 FFT 固定位置。

允许：

- 取指、译码、执行、写回流水化。
- ROM-local predecode，提前拆出 opcode、寄存器号、立即数、访存索引。
- 多周期 `SMUAD/SMUSD`，用更短关键路径换高频。
- 基于 opcode 和依赖关系的通用双发射。
- 安全的 `MOV/MOV`、`LDR/LDR`、`STR/STR`、`SADD16/SSUB16` 同拍退休。
- 依赖可证明安全时，`ASR` 与前序 DSP 写回重叠。
- 寄存器堆、控制信号、工作内存读口复制，用资源换时序。
- 高扇出 reset/control 拆分、局部寄存，降低扇出。

判断标准：

```text
如果换成基础指令测试、排序程序或其他非 FFT 程序后，这个优化仍能按同一规则工作，
通常就是通用 MCU 优化；否则很可能是专用硬件捷径。
```

## 8. 禁止事项

以下行为会破坏验收口径，禁止加入：

- 新增 `FFT`、`BUTTERFLY`、`TWIDDLE` 这类专用 opcode。
- RTL 根据固定 PC、固定 ROM 下标、固定 stage 自动执行 FFT 操作。
- “第 2 条指令默认使用第 1 条指令某个结果”这类固定排布假设。
- 把 twiddle 常量藏进执行单元，只在汇编里看不到。
- 把完整 butterfly 写成隐藏组合逻辑或隐藏状态机。
- 让 `LDR/STR` 对 FFT 地址有特殊语义，但对其他程序不成立。
- 为了降低 `cnt` 改变 `cnt_start/cnt_stop` 边界。
- 删除或弱化基础指令自测，只保留 FFT 能跑。
- 打开 FPGA DSP48 资源来实现 MCU core。

注意：代码中的 “DSP 指令路径” 指 ARM-DSP 风格指令执行逻辑，例如 `SMUAD/SMUSD`。
这不等于允许使用 Xilinx FPGA 的 DSP48 物理资源。

## 9. DSP 资源约束

老师明确要求 MCU 内核不能使用 DSP 资源。推荐 Vivado 设置：

```text
synthesis -max_dsp 0
```

开发者交付前必须检查：

- 综合/实现利用率报告中 DSP 数量为 `0`。
- 如果报告中 `DSPs` 不为 0，不能解释为“ARM DSP 指令需要 DSP 资源”，应继续改 RTL 或约束。
- `SMUAD/SMUSD` 等 ARM-DSP 指令应由 LUT/FF 实现，不应映射到 DSP48。

如果将来测试平台确实需要 DSP，需要单独证明 MCU core 本身没有使用 DSP；但当前最简单、
最稳妥的做法是整个工程 `max_dsp=0`。

## 10. I/O、内存与计数边界

当前 FFT 上板数据流：

```text
test_ROM/test_vector_in
  -> mcu_fft_system 输入加载、bit-reversal、16-bit to 32-bit 打包
  -> mcu4_multicycle_core 通用数据内存 dmem_bank0/dmem_bank1
  -> worker 执行 ROM 指令
  -> mcu_fft_system 32-bit to 16-bit 输出拆包和 dump
  -> verify_RAM/verify_vector_out
```

对外展示时：

- `test_ROM`、`verify_RAM`、`cnt_test` 是 PPT 指定的上板观测重点。
- FFT 性能版 ILA 保持最小集合：`test_vector_in`、`cnt_test`、
  `verify_ram_addr`、`verify_vector_out`。不要为了调试方便在性能 bitstream
  中长期保留宽 `pc_debug`/`instr_debug` 或回读 FSM。
- FFT 正确性以 `verify_RAM` 输出结果为准。
- `cnt_test` 只统计指令执行窗口，以老师聊天记录为准。
- `cnt_start` 应靠近第一条 worker 指令读取。
- `cnt_stop` 应靠近所有 active worker 最后一条指令完成或 halt。

`dmem_bank0/dmem_bank1` 是 MCU 的工作数据内存，不是外部 `verify_RAM`。它可以理解成两块小数据内存，也可以理解成一块数据内存的两个地址区域。实现上可以为了多核并行和时序复制读口，但对指令来说仍应表现为普通 `LDR/STR` 可访问的工作内存。

边界规则：

- `mcu4_multicycle_core` 只暴露通用 `dmem_*` 访问口：选 bank、3-bit word 地址、32-bit 数据。
- FFT 的外部 16-bit 输入、real/imag 拼包、`BITREV_ORDER` 装载、输出高低半字拆包，都必须放在 `mcu_fft_system` 或更外层 wrapper。
- `mcu4_multicycle_core` 内不要恢复 `input_we/input_waddr/input_wdata` 或 `output_raddr/output_rdata` 这类 FFT stream 端口。

`mcu4_multicycle_core` 的职责只能是：

```text
外部通用 dmem 写口/读口
  -> 内部 dmem_bank0/dmem_bank1
  -> ACTIVE_CORES 个 worker core
  -> halted/illegal/debug 汇总
```

它可以为了多核并行和时序复制 data memory 读口，也可以把 worker 写入广播到各个 replica；
但它不能再知道“第几个 FFT 输入样本”“输出 real/imag 第几个槽”这类系统协议。换句话说：

```text
mcu_fft_system 负责外部实验平台协议和 FFT 数据格式适配
mcu4_multicycle_core 负责通用 MCU core 集群和通用 data memory
mcu4_worker_core 负责单个 worker 的取指、译码、执行、访存和 halt/illegal
```

如果以后新增非 FFT 程序，应复用同一个 `dmem_*` 口预装输入、读回输出；不要在
`mcu4_multicycle_core` 增加 `sort_input_*`、`filter_output_*`、`fft_input_*` 等程序专用端口。

## 11. 基础指令测试要求

基础指令测试不能只靠 FFT 间接证明。必须保留：

```text
PROGRAM_ID = 1
ACTIVE_CORES = 1
SELFTEST_ROM
asm/mcu4_basic_selftest.s
```

板级 basic top 应例化完整 `mcu4_multicycle_core`，通过 `PROGRAM_ID=1` 和 `ACTIVE_CORES=1`
选择单核基础测试；不要为了方便直接例化 `mcu4_worker_core` 绕过数据内存封装。

basic 上板 checker 应检查通用行为结果，而不是依赖某个私有内部实现细节：

```text
illegal 必须为 0
worker 必须在 timeout 前 halt
data[1..7] 必须读回 MOV/ADD/SUB/AND/ORR/LDR/控制流 signature
dmem_bank1 必须保持 0，用于证明 basic 程序没有误访问第二数据区
```

`pc_debug/instr_debug` 可以作为 ILA trace 或仿真辅助，但不要让板级 `test` 信号依赖逐周期
debug 指令字完全对齐；这类检查容易在上板时把调试显示时序误判成功能错误。

基础测试至少覆盖：

```text
MOV, ADD, SUB, AND, ORR, LDR, STR, B, BL, MOV pc, lr
```

上板或仿真展示基础指令时，优先使用通用 trace：

```text
pc_debug
instr_debug
寄存器写回目的寄存器和值
存储写入地址和值
halt / illegal
```

不要为每条基础指令单独拉一堆专用信号。更好的证明方式是让指令把结果写入通用结果区，
或者抓通用写回/存储 trace。

## 12. 新增程序流程

以后如果加入排序、滤波、矩阵运算或其他程序，按以下流程：

1. 在 `rtl/mcu4_worker_instr_rom.vhd` 增加显式 ROM 常量。
2. 扩展 `PROGRAM_ID` 选择逻辑。
3. 在 `asm/` 增加可读汇编清单。
4. 根据程序需要选择 `ACTIVE_CORES=1..4`。
5. 增加 testbench 或上板检查脚本，验证输出、halt、illegal。
6. 保证 `PROGRAM_ID=0` FFT 和 `PROGRAM_ID=1` 基础测试仍能通过。

如果新程序需要 ISA 尚不支持的能力，应该扩展通用指令、decoder 和执行路径；不要新增只服务
该程序的隐藏数据通路。

## 13. 提交前检查清单

功能检查：

```text
mcu4_worker_core_min_arm_tb
mcu4_multicycle_core_min_arm_tb
mcu4_multicycle_core_tb
mcu_fft_system_tb
board_top_tb
```

RTL/文档搜索：

```bash
rg "ENABLE_FFT_WINDOW_FUSION|scheduled_pair_kind_for_pc|PC-scheduled|fft_.*window" rtl docs
rg "butterfly|twiddle|FFT" rtl
rg "buf_a|buf_b|WORK_BUF|complex8_array_t|WOP_LDR_A\\b|WOP_STR_B\\b" rtl docs asm --glob '!docs/DEVELOPMENT_CONSTRAINTS.md'
```

第二条搜索不是要求完全没有 `FFT` 字样，而是检查是否出现了专用 opcode、固定 PC 窗口、
隐藏 butterfly 或隐藏 twiddle 执行单元。

Vivado 报告检查：

- implementation timing summary 中 setup/hold 均满足，WNS/WHS 不为负。
- utilization 中 DSP 数量为 `0`。
- top 是预期的 `board_top`，不是旧工程或旧 top。
- 记录实际频率、`cnt_test`、`cnt * period`。

文档检查：

- 汇编和机器码能对应。
- 报告能说明为什么这是 MCU 指令执行，而不是 FFT 专用硬件。
- 优化方法能按通用微架构解释，例如流水、多周期、双发射、寄存器复制、扇出优化。

一句话红线：

```text
性能可以用资源堆、用流水堆、用多核堆；但不能用“RTL 偷偷知道这是 FFT”来堆。
```
