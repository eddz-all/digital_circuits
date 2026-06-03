# FFT8 后续优化总计划

更新时间：2026-06-03

本文档记录 V5 之后的总优化路线。当前主线仍是 `dsp` 分支，V1-V5 已完成；V5 为 ARM-real `SMLAD + STMIA` 版本，达到 `59 timed_steps`。后续优化按以下顺序推进：

```text
1. 流水线 / 关键路径寄存化
2. 8 核并行
3. 单核多发射
```

## 1. 当前基线

当前已完成速度表按 `50 MHz` 计算：

| 版本 | 说明 | 指令数 | DONE 前执行指令数 | timed_steps / cnt_test | 速率 @50MHz | 相对 V1 加速 |
|---|---|---:|---:|---:|---:|---:|
| V1 | scalar baseline | 286 | 285 | 276 | 18.12 万次/秒 | 1.00x |
| V2 | packed DSP | 120 | 119 | 109 | 45.87 万次/秒 | 2.53x |
| V3 | ARM-safe architecture DSP, LDMIA/STRD | 98 | 97 | 88 | 56.82 万次/秒 | 3.14x |
| V4 | ARM-strict exact DSP, SSAX/SSUB16 | 88 | 87 | 78 | 64.10 万次/秒 | 3.54x |
| V5 | ARM-strict 59, SMLAD/STMIA | 78 | 77 | 59 | 84.75 万次/秒 | 4.68x |

速率口径：

```text
throughput = clock_frequency / cnt_actual
hardware_efficiency = throughput / (6 * LUT + 10 * FF)
```

后续必须同时记录：

```text
cnt_actual
Fmax_actual
throughput
LUT / FF / DSP / BRAM
hardware_efficiency
WNS / TNS / critical path
```

## 2. 规则边界

课程 PPT 中明确允许：

```text
ALU/MCU 结构不限制，但必须严格遵守 ARM 指令集。
可采用流水、超流水、单指令多操作、硬件加速核、多核并行等结构。
```

同时 FFT 应用要求：

```text
全部设计必须以 MCU 的指令形式完成，不能做专用硬件芯片。
最后要求展示对应汇编指令。
cnt_test 从第一个数据读入开始计数，一旦开始，中间禁止停止。
最后一个数据输出完成后停止计数。
Timing report 必须无 violation，WNS 必须为正。
```

因此后续优化可以改变 MCU 微架构，但必须守住：

```text
1. 汇编层面的 mnemonic 必须是 ARM 真实存在的指令。
2. 不能新增 FFT8 / CMULQ15 / LDCPLX / STCPLX / fixed-twiddle 等自创指令。
3. 不能把输入直接接专用 FFT/DFT 电路后写 verify_RAM。
4. cnt_test 必须统计真实指令执行过程中的 wall-clock cycle。
5. 输出必须来自一个或多个 MCU core 执行汇编程序后的结果。
```

## 3. 阶段 0：建立 Vivado 基线

在做结构优化前，先建立 V5 的上板前 timing/resource baseline。不要先凭猜测改 RTL。

建议 Vivado Tcl 报告：

```tcl
report_timing_summary
report_timing -max_paths 20
report_utilization
report_qor_suggestions
report_methodology
report_design_analysis
```

需要记录：

```text
1. 当前 V5 post-implementation WNS / TNS。
2. 当前 V5 可达到的 Fmax。
3. 当前 V5 LUT / FF / DSP / BRAM。
4. critical path 起点、终点、logic delay / route delay 比例。
5. 是否存在 unconstrained path、missing clock、reset fanout、high fanout net。
```

阶段 0 交付物：

```text
docs/fft8_v5_vivado_baseline.md
vivado/reports/v5_timing_summary.rpt
vivado/reports/v5_utilization.rpt
```

如果课程工程目录不在本仓库中，也可以先把报告摘要放进文档，不强制提交 Vivado 生成目录。

## 4. 阶段 1：流水线 / 关键路径寄存化

### 4.1 目标

主攻 `Fmax`，尽量保持 V5 汇编、机器码和 ARM-real 指令语义不变。

```text
V5 当前逻辑口径：
  timed_steps = 59
  throughput @50MHz = 84.75 万次/秒

阶段 1 目标：
  提升上板 Fmax。
  cnt_actual 允许小幅增加，但 throughput 必须提升。
```

判断公式：

```text
pipeline_throughput = Fmax_pipeline / cnt_pipeline
```

只有当：

```text
Fmax_pipeline / cnt_pipeline > Fmax_v5_single_cycle / 59
```

阶段 1 才算成功。

### 4.2 当前 RTL 可能的关键路径

当前 `rtl/z99_mcu_v1_core.vhd` 是单周期长路径：

```text
pc_reg
  -> instr_rom
  -> decoder
  -> regfile read
  -> ALU
  -> data_mem
  -> writeback mux
  -> regfile / flags / PC
```

V5 额外引入的高风险组合路径：

```text
SMLAD:
  两个 signed16 乘法 + 32-bit accumulator。

LDMIA / STMIA:
  512-bit bulk read/write data path。

bulk_store_data:
  regfile bulk_rd 经过 regmask 重排后送 data_mem。

bulk_wd:
  bulk_mem_rd 经过 regmask 重排后写回 regfile。

output_mem / work_ram:
  bulk_store loop、popcount/regmask 相关选择。
```

### 4.3 第一轮：非架构 timing cleanup

优先不改变指令可见 latency，只做 Vivado 友好的 RTL 清理。

候选动作：

```text
1. 明确小容量 ROM/RAM 的综合 style。
   当前 instr_rom / input_mem / work_ram / output_mem 都是小容量。
   需要在 Vivado 中比较 distributed / registers / block 的 Fmax 和资源。

2. 检查数据通路 reset。
   控制状态需要 reset，宽数据通路和 bulk data 不要无脑 reset。
   目标是降低 reset fanout，改善 frequency、area 和 routing。

3. 拆分 512-bit bulk mux。
   不要在一个组合进程里同时完成 regmask 扫描、数据重排、memory route。

4. 优化 SMLAD 实现。
   观察是否推断 DSP48，或者是否需要显式结构化乘法以改善 timing。

5. 运行 report_qor_suggestions。
   先用工具报告定位常见 timing closure 问题，再决定是否手动插寄存器。
```

本轮验收：

```text
GHDL core TB 通过。
V5 Python checker 通过。
Vivado WNS 改善或 Fmax 提升。
cnt_test 不变，仍为 59。
```

### 4.4 第二轮：轻量关键路径寄存化

如果 cleanup 后 Fmax 仍不足，开始插入有限 pipeline register。

推荐优先寄存化模块边界：

```text
instr_reg:
  ROM 输出寄存化。

decode_reg:
  decoder 控制信号寄存化。

operand_reg:
  regfile 读出的 rd1/rd2/rd3 寄存化。

alu_result_reg:
  ALU 输出寄存化。

mem_result_reg / wb_reg:
  data_mem 输出和 writeback 数据寄存化。
```

先不要直接实现复杂五级流水线。目标是找到最小寄存化点，让 critical path 明显变短。

需要同步处理：

```text
valid bit
instruction latency
branch/DONE 行为
cnt_test 按真实 cycle 统计
testbench 等待周期更新
```

### 4.5 第三轮：正式 in-order pipeline

如果轻量寄存化仍不够，再实现 3 级或 4 级顺序流水线。

3 级建议：

```text
IF:
  PC + instruction fetch

ID:
  decode + regfile read

EX/MEM/WB:
  ALU + memory + writeback
```

4 级建议：

```text
IF:
  PC + instruction fetch

ID:
  decode + regfile read

EX:
  ALU / address generation / SMLAD

MEM/WB:
  memory access / register writeback / output write
```

必须实现：

```text
1. pipeline valid bit。
2. ALU forwarding。
3. load-use stall。
4. LDMIA bulk-load stall 或 forwarding。
5. STMIA commit 语义。
6. branch flush。
7. DONE self-loop 的 halted 判断。
8. cnt_test 真实 cycle 统计。
```

阶段 1 风险：

```text
FFT 汇编数据相关密集，若没有 forwarding，会插入大量 stall。
LDMIA / STMIA 是宽指令，流水化后要明确它们的 commit cycle。
分支自循环 DONE 的 halted_debug 断言要随 pipeline latency 调整。
```

阶段 1 推荐通过门槛：

```text
Fmax >= 100 MHz 且 cnt_pipeline <= 70
```

对应速度约：

```text
100 MHz / 70 = 142.86 万次/秒
```

这显著高于 V5 在 50 MHz 下的 `84.75 万次/秒`。

## 5. 阶段 2：8 核并行

### 5.1 目标

主攻单次 FFT 的 wall-clock `cnt_actual`。课程允许多核并行，但结果仍必须来自 MCU core 执行汇编。

推荐方案：

```text
8-core parallel DFT-bin design
```

每个 core 负责一个频点：

```text
core0 -> X0
core1 -> X1
core2 -> X2
core3 -> X3
core4 -> X4
core5 -> X5
core6 -> X6
core7 -> X7
```

每个输出频点按公式计算：

```text
X[k] = sum(n=0..7) x[n] * W8^(k*n)
```

这不是硬件旁路，前提是每个 core 内部都执行真实 ARM mnemonic 汇编。

### 5.2 推荐系统结构

```text
input_loader:
  从 test_ROM 读 16 个 16-bit 输入槽位。
  写入 input_snapshot。

input_snapshot:
  保存 8 个复数输入。
  可广播给 8 个 core。

core[0..7]:
  每个 core 有自己的 PC / decoder / regfile / ALU。
  每个 core 执行自己的 X[k] 程序。
  每个 core 只写自己的 result_real/result_imag。

output_arbiter:
  等所有 core done。
  按输出顺序写 verify_RAM。
```

`cnt_test` 统计：

```text
cnt_8core =
  input_load_cycles
  + max(core0_cycles ... core7_cycles)
  + output_write_cycles
  + sync_overhead
```

注意：

```text
input loading、输入复制、等待最慢 core、输出仲裁全部计入 cnt_test。
cnt_test 从第一个 test_ROM 数据读入开始，中间不能停止。
```

### 5.3 为什么先做 DFT-bin 而不是多核 FFT butterfly

8 点 FFT 每一级 butterfly 可以并行，但级间必须同步：

```text
stage 1 -> barrier -> stage 2 -> barrier -> stage 3
```

如果多个 core 协同执行 butterfly，需要共享 work RAM 或多 bank RAM，还要处理 barrier 和访存冲突。

DFT-bin 方案的优点：

```text
1. 核间基本没有数据依赖。
2. 每个 core 输出两个槽位，写冲突小。
3. 各 core 程序容易解释。
4. 可以清楚展示每个 core 的汇编。
```

缺点：

```text
1. 会重复读取同一组输入。
2. X1/X3/X5/X7 需要 0.707 twiddle 乘法，最慢 core 决定总 cnt。
3. 资源开销大，硬件效率榜可能变差。
```

### 5.4 阶段 2 先做估算

不要先改 RTL。先写估算脚本：

```text
tools/estimate_fft8_8core_bins.py
```

以及每个 core 的候选汇编：

```text
asm/fft8_v7_core0_x0.s
asm/fft8_v7_core1_x1.s
asm/fft8_v7_core2_x2.s
asm/fft8_v7_core3_x3.s
asm/fft8_v7_core4_x4.s
asm/fft8_v7_core5_x5.s
asm/fft8_v7_core6_x6.s
asm/fft8_v7_core7_x7.s
```

估算脚本需要输出：

```text
每个 core 的指令数。
每个 core 从 start 到 result ready 的 cycle。
总 input_load_cycles。
总 output_write_cycles。
估算 cnt_8core。
对拍 correctness。
```

推荐进入 RTL 的门槛：

```text
cnt_8core <= 35:
  值得实现。

35 < cnt_8core <= 45:
  视资源和时间决定。

cnt_8core > 45:
  暂不建议实现，优先继续阶段 1。
```

### 5.5 RTL 实施顺序

如果估算通过，按这个顺序实现：

```text
1. 2-core prototype。
   先做 X0 / X1，验证 input_snapshot、core start/done、output arbiter。

2. 8-core top。
   扩展到 X0..X7。

3. 统一 cnt_test 控制。
   从 input_loader 第一读开始，到 output_arbiter 最后一写结束。

4. ILA 观测口。
   test_vector_in、verify_vector_out、cnt_test、core_done[7:0]。

5. Vivado resource/timing。
   记录速度榜和硬件效率榜影响。
```

阶段 2 风险：

```text
8 个 core 资源显著增加。
input_snapshot 广播 fanout 可能影响 Fmax。
output_arbiter 写 verify_RAM 的周期必须算进 cnt。
答辩时必须说明不是专用 DFT 电路，而是 8 个 MCU core 执行汇编。
```

### 5.6 多核存储结构补充研究

如果完全不考虑资源，增加重复 RAM 或多 bank RAM 是减少多核共享存储冲突的正确方向。

但需要区分：

```text
RAM 冲突可以靠复制、分 bank、ping-pong buffer 缓解。
FFT 级间依赖不能靠 RAM 复制消除。
```

Radix-2 FFT 的级间依赖仍然存在：

```text
Stage 2 必须等待 Stage 1 的中间结果。
Stage 3 必须等待 Stage 2 的中间结果。
```

因此多核 radix-2 FFT 即使有足够 RAM，也仍需要 stage barrier；RAM 复制只能减少 barrier 前后的读写仲裁等待。

可选存储结构：

```text
1. 输入复制。
   适合 8-core DFT-bin。
   先把 16 个输入槽位复制到每个 core 的本地 input RAM 或 input_snapshot replica。
   之后 8 个 core 读输入无冲突。

2. 多 bank ping-pong 工作 RAM。
   适合多核协同 radix-2 FFT butterfly。
   stage_buf_a 作为当前级输入，stage_buf_b 作为当前级输出。
   每级结束后交换 a/b。
   每个 buffer 分成 bank0..bank7，尽量让并行 butterfly 读写不同 bank。

3. 每核本地 scratch + 显式交换。
   每个 core 有本地 RAM/register file。
   stage 间通过 result bus 或交换网络传递必要中间值。
   控制复杂度最高，不建议作为第一版多核实现。
```

资源不受限时，最快潜力并不一定是 8-core DFT-bin。

```text
8-core DFT-bin:
  优点是几乎无核间同步，最容易解释。
  缺点是重复计算多，X1/X3/X5/X7 最慢 core 决定总 cnt。

多核 radix-2 FFT butterfly:
  优点是总算术量少。
  缺点是有 stage barrier，需要多 bank/ping-pong RAM 和同步控制。
```

当前判断：

```text
最稳答辩和实现：
  8-core DFT-bin。

资源无限时最高速度潜力：
  多核 radix-2 FFT butterfly + 多 bank/ping-pong RAM。

下一步若重启多核研究：
  先分别写 8-core DFT-bin 和 4/8-core radix-2 butterfly 的 cnt 估算脚本，再决定实现路线。
```

## 6. 阶段 3：单核多发射

### 6.1 目标

主攻 `cnt_actual`，仍保持单个 core，对外仍是 ARM-real 指令流。

推荐从：

```text
2-way in-order superscalar
```

开始，而不是直接做乱序或 VLIW。

### 6.2 先做离线调度分析

不要先写 RTL。先分析 V5 指令流在 2-way issue 下理论能降多少。

建议脚本：

```text
tools/analyze_fft8_v5_dual_issue.py
```

限制条件：

```text
1. 每周期最多发射 2 条相邻指令。
2. branch 独占。
3. 每周期最多 1 条 memory/bulk 指令。
4. 两条指令不能写同一个寄存器。
5. 第二条指令不能读取第一条本周期写的寄存器。
6. LDMIA / STMIA / SMLAD 是否允许与普通 ALU 同发射要单独配置。
7. 保持顺序提交，不允许改变可见语义。
```

进入 RTL 的门槛：

```text
如果 V5 59 cnt 能降到 <= 45:
  可以考虑实现。

如果只能降到 50 左右:
  不建议实现，工程成本过高。
```

### 6.3 RTL 实现范围

如果进入 RTL，至少需要：

```text
双取指。
双译码。
更多 regfile 读端口。
两个写回端口或写回仲裁。
至少两条执行 lane。
data hazard 检测。
structural hazard 检测。
forwarding network。
branch flush。
memory/bulk 指令互斥规则。
```

难点：

```text
多端口 regfile 会显著增加 LUT/FF。
forwarding 和 hazard 逻辑可能拉低 Fmax。
LDMIA / STMIA 已经是单条宽访存，多发射时不能轻易和另一条访存并行。
```

阶段 3 风险最高，排在最后。

## 7. 总里程碑

建议里程碑：

| 里程碑 | 内容 | 决策点 |
|---|---|---|
| M0 | V5 Vivado timing/resource baseline | 确认当前 Fmax 和 critical path |
| M1 | V5 timing cleanup | 不改 cnt，观察 Fmax 是否提升 |
| M2 | 轻量 pipeline prototype | 比较 `Fmax/cnt` 是否优于 V5 |
| M3 | 8-core Python/汇编估算 | 判断是否值得做 RTL |
| M4 | 2-core prototype | 验证 input/output/control 结构 |
| M5 | 8-core full top | 形成多核速度榜候选 |
| M6 | dual-issue 离线调度分析 | 判断收益是否足够 |
| M7 | dual-issue RTL prototype | 仅在 M6 收益足够时启动 |

## 8. 验证策略

日常局部验证：

```text
文档改动：
  不跑 checker。

汇编/模型改动：
  只跑当前版本 Python checker。

RTL 局部改动：
  跑相关 GHDL TB。
  ALU 改动跑 mcu_v1_alu_tb。
  decoder 改动跑 mcu_v1_decoder_tb。
  core/memory 改动跑 mcu_v1_core_tb。
```

完整回归触发条件：

```text
1. 准备最终交付。
2. 准备 commit/tag 代码实现。
3. 修改共享 RTL，可能破坏 V1-V5。
4. 用户明确要求完整回归。
```

完整回归命令仍按现有文档执行：

```bash
python3 tools/test_fft8_v1_mcu32_basic.py
python3 tools/test_fft8_v2_packed_dsp.py
python3 tools/test_fft8_v3_arch_dsp.py
python3 tools/test_fft8_v4_arm_strict.py
python3 tools/test_fft8_v5_arm_strict_59.py
```

Vivado/VHDL 兼容要求继续保持：

```text
不要使用 process(all)。
不要使用 use std.env.all。
不要使用 finish。
RTL/TB 使用显式敏感列表。
core TB 必须用 sim_done 停止 clock。
```

## 9. 推荐优先级结论

按用户制定顺序执行：

```text
1. 流水线 / 关键路径寄存化
2. 8 核并行
3. 单核多发射
```

理由：

```text
流水线 / 关键路径寄存化：
  最适合提高上板 Fmax。
  对现有 ARM-real 汇编和 V5 语义冲击最小。

8 核并行：
  PPT 明确允许多核并行。
  规则上可行，但要先证明最慢 X[k] core 足够短。
  资源开销大，速度榜优先，硬件效率榜可能吃亏。

单核多发射：
  理论上能降低 cnt。
  但 hazard、forwarding、多端口 regfile、访存冲突复杂度最高。
  只有离线分析显示收益足够时才进入 RTL。
```

## 10. 参考资料

```text
课程要求:
  /Users/eddz/Downloads/数字电路实验_MCU.pptx

AMD / Vivado:
  https://docs.amd.com/r/2021.2-English/ug949-vivado-design-methodology/Timing-Closure
  https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/Pipelining-Considerations?contentId=yh_5R1VxGDBerBZcti~KLQ
  https://docs.amd.com/r/en-US/ug949-vivado-design-methodology/When-and-Where-to-Use-a-Reset
  https://www.xilinx.com/support/documents/sw_manuals/xilinx2022_2/ug901-vivado-synthesis.pdf

ARM:
  https://developer.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-21-42/7563.ARM-white-paper-_2D00_-DSP-capabilities-of-Cortex_2D00_M4-and-Cortex_2D00_M7.pdf
```
