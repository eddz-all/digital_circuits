# FFT8 Vivado 数据采集清单

更新时间：2026-06-03

本文档用于发给负责 Vivado/上板的同学，收集后续判断 V5 是否需要流水线、以及流水线应该切在哪里所需的数据。

当前最有意义的两个版本是：

```text
V1:
  scalar baseline，基础 reference，用来确认基础 MCU 在 Vivado 下的 timing/resource 底线。

V5:
  当前最快 ARM-real SMLAD + STMIA 版本，用来判断后续流水线和关键路径优化。
```

## 1. 采集目标

当前 V1-V5 的软件/GHDL 结果已经完成。现在需要 Vivado 上的真实 timing/resource 数据，回答四个问题：

```text
1. V1 在 50 MHz 下的 baseline timing/resource 是什么。
2. V5 在 50 MHz 下是否稳定过 timing。
3. V5 相比 V1 的资源和关键路径变化在哪里。
4. V5 如果提高到 75 MHz / 100 MHz，是否还有机会过 timing。
```

这些数据用于判断下一步是：

```text
1. 不需要流水线，只提高时钟约束。
2. 做局部关键路径优化，例如 SMLAD / STMIA / bulk mux。
3. 做 P1/P2/P3 流水线。
```

## 2. 必须保持一致的设置

请尽量用同一个 Vivado 工程、同一个顶层、同一个 FPGA part 和同一套约束，只替换加载的 `.mem` 或程序版本。

目标芯片：

```text
XC7K160T-2FFG676-I
Vivado part: xc7k160tffg676-2
```

时钟约束先用 50 MHz：

```tcl
create_clock -period 20.000 [get_ports clk]
```

如果端口名不是 `clk`，请按实际端口名替换，但请截图或贴出 `.xdc` 中 `create_clock` 这一行。

## 3. 最小必须采集的数据

最少需要 V1 和 V5 各自的以下三项：

```text
1. Timing Summary
2. Utilization
3. Worst Timing Path / Critical Path
```

如果时间有限，优先级是：

```text
V5 Timing Summary
V1 Timing Summary
V5 Worst Timing Path
V1 Worst Timing Path
V5 Utilization
V1 Utilization
```

## 4. 需要跑的版本

### 4.1 必跑：V1

V1 是基础 baseline，用于对比当前最快 V5 的资源、关键路径和 timing 余量。

```text
program: asm/fft8_v1_mcu32_basic.mem
timed_steps: 276
```

必须给：

```text
1. 50 MHz Timing Summary 截图或报告。
2. 50 MHz Utilization 截图或报告。
3. 50 MHz Worst Timing Path 详情。
```

### 4.2 必跑：V5

V5 是当前最快版本，后续优化判断以 V5 为准。

```text
program: asm/fft8_v5_arm_strict_59.mem
timed_steps: 59
```

必须给：

```text
1. 50 MHz Timing Summary 截图或报告。
2. 50 MHz Utilization 截图或报告。
3. 50 MHz Worst Timing Path 详情。
```

### 4.3 可选：V4

V4 用于判断 V5 新增 `SMLAD / STMIA` 是否显著恶化 timing。

```text
program: asm/fft8_v4_arm_strict.mem
timed_steps: 78
```

如果时间够，采集：

```text
V4 Timing Summary + Utilization + Worst Path
```

## 5. Timing Summary 需要的信息

截图或报告里必须能看到：

```text
Setup:
  WNS
  TNS
  Number of Failing Endpoints
  Total Number of Endpoints

Hold:
  WHS
  THS
  Number of Failing Endpoints

Pulse Width:
  WPWS
  TPWS
  Number of Failing Endpoints

底部是否显示:
  All user specified timing constraints are met.
```

例如已知 V1 的 50 MHz 截图里有：

```text
WNS = +4.912 ns
TNS = 0
Failing endpoints = 0
WHS = +0.075 ns
```

但仍建议补齐 V1 的 Utilization 和 Worst Timing Path。V1 的结果也不能替代 V5；V5 因为有 `SMLAD / STMIA / 512-bit bulk path`，critical path 可能不同。

## 6. Worst Timing Path 需要的信息

请在 Vivado 里打开最差 setup path，截图或导出报告。需要看到：

```text
1. Startpoint
2. Endpoint
3. Path Group / Clock
4. Requirement
5. Data Path Delay
6. Logic Delay
7. Route Delay
8. Logic Levels
9. 具体经过的 cell/net 名称
```

重点关注 path 是否包含这些模块或信号：

```text
instr_rom
decoder
regfile
mcu_v1_alu
SMLAD
bulk_rd
bulk_wd
bulk_store_data
bulk_regmask
data_mem
work_ram
output_mem
wb_data
reset / rst
```

如果 Vivado 可以导出文本，建议命令：

```tcl
report_timing -max_paths 20 -path_type full -file v1_worst_paths_50m.rpt
report_timing -max_paths 20 -path_type full -file v5_worst_paths_50m.rpt
```

## 7. Utilization 需要的信息

截图或报告里请包含：

```text
LUT
LUTRAM
FF
DSP
BRAM
BUFG
```

最重要的是：

```text
LUT
FF
DSP
BRAM
```

因为课程硬件效率公式是：

```text
硬件开销 = 6 * LUT + 10 * FF
硬件效率 = 处理速度 / 硬件开销
```

建议导出命令：

```tcl
report_utilization -file v1_utilization_50m.rpt
report_utilization -file v5_utilization_50m.rpt
```

## 8. 建议额外跑 75 MHz / 100 MHz

V1 和 V5 在 50 MHz 下都建议先跑完整数据。

如果 V5 在 50 MHz 下 WNS 为正，建议继续试 V5：

```tcl
75 MHz:
create_clock -period 13.333 [get_ports clk]

100 MHz:
create_clock -period 10.000 [get_ports clk]
```

每个频率只需要先给 Timing Summary：

```text
V5 @ 75 MHz Timing Summary
V5 @ 100 MHz Timing Summary
```

如果时间充足，也可以补 V1 @ 75 MHz Timing Summary，用来对比基础 core 的频率余量。

判断方式：

```text
如果 75 MHz 仍过 timing:
  可以考虑先不流水线，直接提高时钟。

如果 75 MHz 不过，但 50 MHz WNS 很小:
  需要局部关键路径优化。

如果 100 MHz 接近通过:
  P1 registered fetch 或局部寄存化可能足够。

如果 100 MHz 差很多:
  需要 P2/P3 pipeline 或重构关键路径。
```

## 9. Methodology / DRC 可选但推荐

如果方便，请补：

```tcl
report_methodology -file v5_methodology_50m.rpt
report_drc -file v5_drc_50m.rpt
report_qor_suggestions -file v5_qor_suggestions_50m.rpt
```

这些报告用来判断：

```text
1. 是否有 unconstrained path。
2. 是否有 clock 定义问题。
3. 是否有 reset/high-fanout 问题。
4. Vivado 是否建议 register replication、retiming、physical optimization。
```

## 10. 最终请发回这些文件或截图

最小集合：

```text
1. v1_timing_summary_50m 截图或 .rpt
2. v1_worst_paths_50m 截图或 .rpt
3. v1_utilization_50m 截图或 .rpt
4. v5_timing_summary_50m 截图或 .rpt
5. v5_worst_paths_50m 截图或 .rpt
6. v5_utilization_50m 截图或 .rpt
7. .xdc 里的 create_clock 那一行
```

推荐集合：

```text
1. V1 @ 50 MHz Timing Summary
2. V1 @ 50 MHz Worst 10/20 Paths
3. V1 @ 50 MHz Utilization
4. V5 @ 50 MHz Timing Summary
5. V5 @ 50 MHz Worst 10/20 Paths
6. V5 @ 50 MHz Utilization
7. V5 @ 75 MHz Timing Summary
8. V5 @ 100 MHz Timing Summary
9. V5 Methodology / DRC / QoR Suggestions
10. V4 Timing Summary / Utilization / Worst Path
```

## 11. 收到数据后的判断标准

收到 V1/V5 数据后先做对比：

```text
V1:
  用于确认基础单周期 MCU 的 timing/resource 底线。

V5:
  用于判断当前最快程序的真实 critical path 和流水线必要性。
```

然后按 V5 数据判断：

```text
V5 @ 50 MHz WNS >= 3 ns:
  50 MHz 很稳。
  优先尝试 75/100 MHz，不急着流水线。

V5 @ 50 MHz WNS 在 0~3 ns:
  50 MHz 能过但余量有限。
  先看 worst path，做局部优化或 P1 registered fetch。

V5 @ 50 MHz WNS < 0:
  50 MHz 不过 timing。
  必须先做 timing cleanup，再考虑 pipeline。
```

按 worst path 判断切入点：

```text
path 包含 instr_rom / decoder / regfile:
  优先 P1 registered fetch。

path 包含 SMLAD:
  优先优化 SMLAD / DSP48 映射 / EX stage 寄存化。

path 包含 bulk_store_data / bulk_wd / bulk_regmask:
  优先拆 512-bit bulk mux 或局部寄存化。

path 包含 reset/high fanout:
  优先降低 reset/fanout，不要先盲目加流水线。

path 主要是 route delay:
  考虑 floorplan、register replication、phys_opt，而不是只改算法。
```

## 12. 备注

GHDL 和 Python checker 只验证功能正确，不能替代 Vivado timing。

最终课程验收看：

```text
1. 上板 verify_RAM 输出是否正确。
2. ILA 中 cnt_test 总量。
3. Timing report 是否无 violation。
4. 资源占用。
```

因此 Vivado 数据是决定是否做流水线和如何做流水线的依据。
