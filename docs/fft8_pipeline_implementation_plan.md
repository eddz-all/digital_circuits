# FFT8 流水线实现方法研究

更新时间：2026-06-03

本文档聚焦 V5 之后的第一优先优化方向：

```text
流水线 / 关键路径寄存化
```

目标是提高上板 `Fmax`，同时尽量不破坏 V5 的 ARM-real 汇编口径和 `59 timed_steps` 程序结构。

## 1. 目标与约束

当前 V5：

```text
program: asm/fft8_v5_arm_strict_59.s
instructions: 78
executed before DONE: 77
timed_steps: 59
clock assumption in docs: 50 MHz
throughput @50MHz: 84.75 万次/秒
```

后续真实速度口径：

```text
throughput = Fmax_actual / cnt_actual
```

流水线是否成功，不看 Fmax 单项，而看：

```text
Fmax_pipeline / cnt_pipeline > Fmax_single_cycle / 59
```

课程约束保持不变：

```text
1. 汇编 mnemonic 必须是 ARM 真实存在的指令。
2. 不能新增 FFT8 / custom complex / fixed-twiddle 指令。
3. 不能把 FFT/DFT 作为专用组合硬件旁路。
4. cnt_test 必须统计真实 wall-clock cycle。
5. Timing report 必须无 violation，WNS 必须为正。
```

Vivado/VHDL 兼容要求继续保持：

```text
不要使用 process(all)。
不要使用 use std.env.all。
不要使用 finish。
RTL/TB 使用显式敏感列表。
core TB 用 sim_done 停止 clock。
```

## 2. 当前单周期 core 的关键路径

当前 `rtl/z99_mcu_v1_core.vhd` 是单周期结构：

```text
pc_reg
  -> instr_rom combinational read
  -> decoder
  -> regfile combinational read
  -> ALU / address generation
  -> data_mem combinational read
  -> writeback mux
  -> regfile / flags / PC register
```

主要模块：

```text
rtl/mcu_v1_instr_rom.vhd:
  当前 ROM 是组合读。

rtl/mcu_v1_decoder.vhd:
  当前 decoder 是组合逻辑。

rtl/mcu_v1_regfile.vhd:
  3 个组合读端口。
  1 个普通同步写口。
  1 个 bulk write mask。
  512-bit bulk_rd 组合输出。

rtl/mcu_v1_alu.vhd:
  当前 ALU 是组合逻辑。
  SMLAD 路径包含两个 signed16 乘法和 32-bit accumulator。

rtl/z90_mcu_v1_data_mem.vhd:
  input/work/output 区域组合读。
  output/work 支持 double write 和 bulk_store。
```

V5 最可能影响 Fmax 的组合路径：

```text
SMLAD:
  signed16* signed16 x2 + 32-bit add。

STMIA:
  regfile bulk_rd -> regmask reorder -> data_mem bulk_store。

LDMIA:
  data_mem bulk_read -> regmask reorder -> regfile bulk_wd。

Memory routing:
  addr region decode -> input/work/output mux。

Wide reset/fanout:
  rst、bulk_regmask、reg_bulk_rd、bulk_store_data。
```

## 3. 计数口径对流水线的影响

课程计数从第一个输入数据读入开始，到最后一个输出数据写出结束。

因此流水线填充并不一定全部计入 `cnt_test`：

```text
如果 pipeline fill 发生在第一条 input LDMIA 真正读输入之前，
这部分不应该进入 cnt_test。

如果 pipeline drain 发生在最后一条 output STMIA 真正写 verify_RAM 之后，
这部分也不应该进入 cnt_test。
```

对流水线 core，`cnt_test` 应绑定到外部接口事件，而不是绑定到 PC 或 issue：

```text
cnt_start:
  某条指令在 commit/memory stage 对 input region 执行第一次有效 read。

cnt_stop:
  某条指令在 commit/memory stage 对 output region 执行最后一次有效 write。
```

这意味着：

```text
理想 in-order pipeline 没有 stall 时，cnt_pipeline 可以接近 59。
pipeline fill/drain 主要影响 PC start/halt latency，不一定影响 cnt_test。
真正会增加 cnt 的是 stall、branch flush、multi-cycle memory 或 multi-cycle SMLAD。
```

## 4. 推荐实施路线

按风险从低到高分三轮：

```text
P1: 2-stage registered fetch。
P2: 3-stage in-order pipeline。
P3: 4-stage in-order pipeline with forwarding/stall。
```

不要一开始直接做复杂 5-stage，因为当前 FFT 是直线程序、数据相关密集，复杂 pipeline 的 debug 成本会很高。

## 5. P1：2-stage Registered Fetch

### 5.1 目标

最小化 RTL 改动，先把 ROM/取指从长组合路径中切出去。

当前长路径：

```text
PC -> ROM -> decoder -> regfile -> ALU -> data_mem -> wb
```

P1 目标路径：

```text
Stage IF:
  PC -> ROM -> if_id_instr register

Stage EX:
  if_id_instr -> decoder -> regfile -> ALU -> data_mem -> wb
```

### 5.2 结构

新增 pipeline register：

```vhdl
if_id_valid : std_logic;
if_id_pc    : std_logic_vector(31 downto 0);
if_id_instr : std_logic_vector(31 downto 0);
```

执行阶段使用：

```text
decoder input = if_id_instr
pc_unit input = if_id_pc
```

PC 更新：

```text
normal:
  fetch_pc <= fetch_pc + 4

branch_taken in EX:
  fetch_pc <= branch_target
  if_id_valid <= 0 或插入 bubble
```

### 5.3 Hazard 影响

P1 仍然每周期只执行一条指令，且 decode/regfile/ALU/memory/writeback 都在 EX stage 内完成。

因此：

```text
ALU-after-ALU 数据相关不需要 forwarding。
LDR/LDMIA 后紧跟使用，在当前组合读/同步写语义下仍与单周期 core 接近。
只需要处理 branch flush。
```

原因是当前 `regfile` 在 rising edge 写回，下一条进入 EX 后组合读可看到更新后的寄存器值。

### 5.4 cnt 影响

理想情况下：

```text
cnt_test 仍接近 59。
pipeline fill 在第一条输入读之前，不计入 cnt_test。
DONE branch 发生在最后输出写之后，不计入 timed FFT 区间。
```

### 5.5 P1 验收

```text
1. GHDL mcu_v1_core_tb 通过。
2. V5 Python checker 不变。
3. Vivado critical path 不再包含 PC -> ROM -> decoder 的完整链。
4. cnt_actual 与 59 相同或只小幅变化。
```

P1 是第一版流水线最推荐实现。

## 6. P2：3-stage In-order Pipeline

### 6.1 目标

继续缩短 EX stage，把 decode/regfile read 与 ALU/memory/writeback 分开。

结构：

```text
IF:
  PC -> ROM -> IF/ID register

ID:
  decode + regfile read -> ID/EX register

EX/WB:
  ALU + data_mem + writeback
```

新增 pipeline register：

```text
id_ex_valid
id_ex_pc
id_ex_instr
id_ex_control
id_ex_ra1 / ra2 / ra3 / wa
id_ex_rd1 / rd2 / rd3
id_ex_imm_ext
id_ex_branch_offset
id_ex_bulk_regmask
```

### 6.2 新增 hazard

P2 开始需要处理数据相关。

典型问题：

```asm
SHSUB16 R7, R3, R7
SMLAD   R2, R7, R14, R11
```

`SMLAD` 在 ID stage 读 `R7` 时，前一条 `SHSUB16` 可能尚未写回。

P2 必须实现以下之一：

```text
方案 A：stall。
  当前 ID 指令读取前一条 EX/WB 要写的寄存器时，停 1 cycle。
  实现简单，但 V5 数据相关密集，cnt 会增加很多。

方案 B：EX/WB -> ID operand forwarding。
  如果 ID 读的 raX 等于 EX/WB 的 wa，则用 EX/WB result 替代 regfile rdX。
  实现复杂度适中，强烈推荐。
```

推荐：

```text
P2 必须做 ALU result forwarding。
只靠 stall 不适合 V5。
```

### 6.3 Flags hazard

当前基础指令支持 `CMP / BEQ / BNE`。

如果：

```asm
CMP R0, R1
BEQ TARGET
```

branch 在 ID stage 需要 flag，但 CMP flag 可能尚未提交。

处理方式：

```text
1. 对 conditional branch 增加 flag forwarding。
2. 或遇到 conditional branch 依赖上一条 flag_write 时 stall 1 cycle。
```

V5 FFT 主程序基本无条件分支，仅 DONE `B DONE`，所以第一版 P2 可以先用 stall 处理 flags hazard。

### 6.4 Memory hazard

当前程序主要从 input 读、向 output 写，几乎不使用 work RAM 数据相关。

但为了保留通用 core 语义，需要定义：

```text
LDR result forwarding:
  如果 data_mem read 仍是组合读，LDR result 在 EX/WB stage 可用，可 forward 到 ID。

LDMIA bulk result:
  如果下一条读取 LDMIA 写入的任意 reg，需要 forward 或 stall。
```

建议第一版：

```text
普通 LDR:
  支持 forwarding。

LDMIA:
  检测 id_src_reg 与 ldmia bulk_regmask 相交时 stall 1 cycle。
  因为 LDMIA 可能写多个寄存器，做全量 bulk forwarding 代价较高。
```

### 6.5 P2 验收

```text
1. GHDL mcu_v1_alu_tb / decoder_tb / core_tb 通过。
2. V5 core x0/x1 impulse 输出不变。
3. basic program 仍通过 BL/AND/ORR 等覆盖。
4. Vivado Fmax 相比 P1 继续提升。
5. cnt_pipeline 增幅可接受。
```

如果 P2 因 stall 导致 cnt 明显超过 70，应优先补 forwarding，而不是继续加深流水线。

## 7. P3：4-stage In-order Pipeline

### 7.1 目标

进一步切分 ALU 和 memory/writeback，适合在 P2 仍无法满足 Fmax 时实施。

结构：

```text
IF:
  PC fetch

ID:
  decode + regfile read

EX:
  ALU / address generation / branch target / SMLAD

MEM/WB:
  data memory read/write + regfile writeback
```

### 7.2 Pipeline registers

需要：

```text
IF/ID:
  valid, pc, instr

ID/EX:
  valid, pc, decoded control, operands, src regs, dest reg, imm, branch_offset, regmask

EX/MEM:
  valid, control, alu_result, store_data, store_data2, bulk_store_data, dest reg, regmask, flags

MEM/WB:
  valid, wb_data, dest reg, reg_write, flags, flag_write
```

### 7.3 Forwarding 网络

P3 至少需要：

```text
EX/MEM -> EX operand forwarding:
  ALU result 给下一条 ALU/SMLAD/ASR/PKHBT 等。

MEM/WB -> EX operand forwarding:
  LDR/LDMIA/writeback result 给后续 ALU。

EX/MEM 或 MEM/WB -> store data forwarding:
  STR/STRD/STMIA 使用刚产生的寄存器作为 store data 时，需要转发。

flag forwarding:
  CMP 后紧跟 BEQ/BNE。
```

### 7.4 Stall 条件

必须支持：

```text
load-use:
  ID/EX 当前指令需要读取 EX/MEM 的 LDR 目标寄存器，但数据要到 MEM/WB 才可用。
  插入 1 cycle bubble。

ldmia-use:
  下一条使用 LDMIA bulk_regmask 中任一寄存器。
  第一版可以 stall 1 cycle。

branch:
  branch 在 EX resolve，taken 时 flush IF/ID 和 ID/EX younger instruction。

stmia-after-producer:
  STMIA reglist 包含上一条或上几条待写回寄存器。
  需要 store data forwarding 或 stall。
```

### 7.5 Bulk 指令处理

#### LDMIA

推荐流水语义：

```text
ID:
  读 base Rn，保存 bulk_regmask。

EX:
  计算 addr = Rn + 0。
  计算 writeback = Rn + 4 * popcount(regmask)。

MEM/WB:
  从 data_mem 取得 bulk_read_data。
  依据 regmask 写 bulk_wd。
  同时写回 base Rn。
```

注意：

```text
LDMIA base register 不允许出现在 reglist 中，当前 decoder 已检查。
bulk write 和 base writeback 可能同周期写多个寄存器。
```

#### STMIA

推荐流水语义：

```text
ID:
  根据 regmask 从 regfile bulk_rd 组装 bulk_store_data。
  同时应用 forwarding 或标记需要 stall。

EX:
  计算 addr = Rn + 0。
  计算 writeback = Rn + 4 * popcount(regmask)。

MEM/WB:
  对 work/output 执行 bulk_store。
  写回 base Rn。
```

关键点：

```text
output_mem 仍只保存每个写入 word 的 low16。
不能让 STMIA 自动拆 high16，否则会变成 custom complex store。
```

### 7.6 cnt 影响

P3 没有 stall 时，理论上每周期 commit 一条指令。

`cnt_test` 应以 memory/commit stage 事件计：

```text
first input read commit -> last output write commit
```

可能增加 cnt 的来源：

```text
load-use stall。
ldmia-use stall。
stmia data forwarding 不足导致 stall。
branch flush 如果发生在 timed region 内。
把 SMLAD 或 bulk_store 改成 multi-cycle。
```

V5 是直线 FFT 程序，DONE branch 在最后输出之后，branch flush 不应影响 FFT timed region。

## 8. Hazard 检测建议

### 8.1 源寄存器表

为 decoder 或 pipeline control 增加内部 source metadata：

```text
src1_used
src1_reg
src2_used
src2_reg
src3_used
src3_reg
store_uses_rd2
store_uses_rd3
bulk_store_regmask
dest_used
dest_reg
bulk_dest_mask
flag_read
flag_write
```

这些 metadata 不改变对外 ISA，只用于 pipeline control。

### 8.2 RAW 检测

普通寄存器 RAW：

```text
id_src_reg == ex_dest_reg and ex_reg_write
id_src_reg == mem_dest_reg and mem_reg_write
```

Bulk RAW：

```text
id_src_reg in ex_bulk_dest_mask
id_src_reg in mem_bulk_dest_mask
```

STMIA reglist RAW：

```text
stmia_regmask intersects pending_dest_mask
```

### 8.3 Stall vs Forwarding 策略

推荐第一版：

```text
普通 ALU result:
  forwarding。

LDR:
  若数据同周期可从 MEM/WB forward，则 forward；否则 stall 1 cycle。

LDMIA:
  第一版 stall 1 cycle，避免 512-bit forwarding 网络过大。

STMIA:
  如果 reglist 命中 pending write，第一版 stall。
  后续再补 store-data forwarding。

Flags:
  conditional branch 依赖上一条 CMP 时 stall。
```

理由：

```text
V5 主程序没有普通 LDR、CMP/BEQ/BNE，主要是 LDMIA/STMIA/ALU。
第一版优先让 V5 跑通和提高 Fmax，不必一次性覆盖最优所有通用场景。
```

## 9. PC 与 branch 处理

当前 branch 规则：

```text
branch target = PC + 8 + branch_offset
DONE: B DONE
DONE word = 0xE8FFFFFE
```

流水线中必须保留：

```text
branch 使用该指令自己的 PC。
不能使用 fetch_pc 或已更新 PC 误算 target。
```

建议：

```text
IF/ID 和 ID/EX 都携带 instr_pc。
branch resolve stage 使用 instr_pc + 8 + offset。
```

DONE halted 判断：

```text
如果 branch_taken 且 branch_target == instr_pc，则 halted_debug = 1。
```

不要用 fetch_pc 判断 self-loop，否则流水线下容易错。

## 10. cnt_test 硬件建议

当前 GHDL testbench 主要看 `halted_debug`、PC 和输出。真正上板需要独立 `cnt_test`。

流水线下建议统一事件：

```text
input_read_commit:
  valid instruction 在 MEM/commit stage。
  mem_read = 1 或 bulk_load = 1。
  addr region = INPUT。

output_write_commit:
  valid instruction 在 MEM/commit stage。
  mem_write = 1。
  region = OUTPUT。
```

计数器：

```text
if rst:
  cnt_running <= 0
  cnt_done <= 0
  cnt_test <= 0

elsif input_read_commit and not cnt_running and not cnt_done:
  cnt_running <= 1
  cnt_test <= 1

elsif cnt_running:
  if output_write_commit_last:
    cnt_done <= 1
    cnt_running <= 0
  else:
    cnt_test <= cnt_test + 1
```

`output_write_commit_last` 可以按两种方式实现：

```text
1. 简单版本：
   检测写 output region 且写到最后槽位。
   V5 最后一条 STMIA 写 slots 8..15，因此最后槽位为 15。

2. 通用版本：
   output_mem 记录写入最高槽位，当一次 store 覆盖 slot 15 时停止。
```

注意：

```text
STMIA 一条指令写多个 output slots。
cnt_stop 应发生在这条 STMIA commit 的同一个 cycle。
```

## 11. V5 指令流对流水线的影响

V5 timed region 大致为：

```text
输入/打包:
  LDMIA x2
  PKHBT x8
  SSUB16 x1

Stage 1 / Stage 2:
  SHADD16 / SHSUB16
  SMUAD / SMUSD / SMLAD
  ASR
  PKHBT
  SSAX

输出:
  MOV R10,#512
  final SHADD16 / SHSUB16
  ASR imag extraction
  STMIA x2
```

数据相关密集示例：

```asm
SHSUB16 R7, R3, R7
SMLAD   R2, R7, R14, R11
SMUSD   R10, R7, R14
ASR     R10, R10, #15
ASR     R2, R2, #15
PKHBT   R7, R10, R2, LSL #16
```

如果 P2/P3 没有 forwarding，这类片段会频繁 stall。

因此流水线收益关键不是 stage 数，而是：

```text
能否用少量 forwarding 保持接近 1 instruction/cycle。
```

## 12. 实施文件建议

不要直接覆盖当前 `mcu_v1_core`。建议新增 pipeline core，保留 V1-V5 单周期回退点。

候选新增文件：

```text
rtl/z99_mcu_v1_core_pipe2.vhd
rtl/z99_mcu_v1_core_pipe3.vhd
rtl/mcu_v1_pipeline_ctrl.vhd
tb/mcu_v1_core_pipe_tb.vhd
docs/fft8_pipeline_implementation_plan.md
docs/fft8_pipeline_results.md
```

也可以用 generic 控制：

```text
mcu_v1_core:
  PIPELINE_MODE = 0 / 2 / 3 / 4
```

但第一版建议新增独立 entity，便于回退和对比。

## 13. 实施步骤

### Step 1: Vivado baseline

```text
1. 综合/实现当前 V5。
2. 保存 timing/resource 报告。
3. 找出 top 20 critical paths。
4. 判断主要瓶颈是 ROM、ALU、bulk mux、memory 还是 reset/fanout。
```

### Step 2: P1 pipe2 core

```text
1. 新增 z99_mcu_v1_core_pipe2.vhd。
2. 增加 IF/EX register。
3. 保留 EX stage 中的现有 decoder/regfile/ALU/data_mem/writeback。
4. 修正 branch target 使用 instr_pc。
5. 修正 halted_debug 使用 execute-stage PC。
6. 新增 core pipe TB。
```

### Step 3: P1 验证和 Vivado 对比

```text
1. 跑 GHDL pipe TB。
2. 用 V5 x0/x1 impulse 验证输出。
3. 跑 Vivado timing/resource。
4. 比较 Fmax 和 cnt。
```

如果 P1 已满足速度目标，先停止，不急着 P2/P3。

### Step 4: P2 pipe3 core

```text
1. 增加 ID/EX register。
2. 增加普通 ALU forwarding。
3. 增加 LDMIA/STMIA 简单 stall。
4. 增加 flag hazard stall。
5. 验证 basic/V5。
```

### Step 5: P3 pipe4 core

仅当 P2 Fmax 不够时进行：

```text
1. 增加 EX/MEM 和 MEM/WB register。
2. 实现 load-use stall。
3. 实现 store data forwarding 或 stall。
4. 优化 bulk 指令 commit。
5. 再跑 Vivado timing/resource。
```

## 14. 验收标准

每个 pipeline 版本必须记录：

```text
pipeline stage count
cnt_actual
Fmax_actual
throughput
LUT / FF / DSP / BRAM
hardware_efficiency
V5 x0/x1 GHDL output
Python model/checker result
Vivado WNS
```

建议通过门槛：

```text
P1:
  cnt <= 61，Fmax 有明确提升。

P2:
  cnt <= 65，Fmax 明显优于 P1。

P3:
  cnt <= 70，Fmax 至少达到 100 MHz。
```

若出现：

```text
Fmax 提升 < 20%，但 cnt 增加明显。
```

则该 pipeline 版本不值得作为主线。

## 15. 风险与应对

### 15.1 Stall 太多

风险：

```text
V5 数据相关密集，pipeline 深了但 cnt 增加。
```

应对：

```text
优先补 ALU forwarding。
LDMIA/STMIA 先 stall，确认影响后再决定是否做 bulk forwarding。
```

### 15.2 Fmax 没提升

风险：

```text
critical path 仍在 SMLAD 或 bulk mux。
```

应对：

```text
根据 report_timing 精准插寄存器。
拆分 SMLAD 或明确 DSP48 映射。
拆分 bulk_store_data / bulk_wd 组合路径。
```

### 15.3 Branch / halted 判断错

风险：

```text
流水线中 PC 多份存在，DONE self-loop 判断错。
```

应对：

```text
所有 pipeline stage 携带 instr_pc。
branch target 使用 instr_pc + 8 + offset。
halted_debug 只看 branch 指令所在 stage。
```

### 15.4 cnt_test 口径错

风险：

```text
把 issue cycle 当成 input/output commit cycle。
```

应对：

```text
cnt_start/cnt_stop 绑定到 memory/commit stage 的外部接口事件。
STMIA bulk output 在 commit cycle 停止计数。
```

## 16. 推荐结论

当前最推荐的实现路径：

```text
1. 先跑 Vivado baseline，确认 critical path。
2. 先做 P1 2-stage registered fetch。
3. 如果 P1 不够，再做 P2 3-stage in-order pipeline + ALU forwarding。
4. P3 4-stage 只在 P2 Fmax 不够时做。
```

不建议：

```text
一开始做完整 5-stage。
一开始把 LDMIA/STMIA 拆成多周期。
一开始做复杂 bulk forwarding。
一开始改 V5 汇编或 V1-V5 已验证文件。
```

## 17. 参考资料

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
