# 三人学习分工与答辩准备

这份分工不按文件硬切，而按老师可能追问的知识域来分。目标是三个人都知道系统全貌，但每个人有明确主责，答辩时可以自然接话。

## 共同底线

三个人都必须能说清楚这几句话：

- 本工程是四核多周期 MCU，不是 FFT 专用硬件。
- FFT 只是写进指令 ROM 的一套程序，换成基础指令测试、排序程序或其他程序，core 仍然按指令执行。
- 每个 worker 有自己的 32-bit 指令 ROM、寄存器堆、ALU/DSP 执行路径。
- 数据存储目前分成 `dmem_bank0` 和 `dmem_bank1`。对外可以说是两块小数据内存，也可以说是一块数据内存里的两个地址区域。
- `PROGRAM_ID` 选择运行 FFT 程序还是基础测试程序，`ACTIVE_CORES` 选择启用几个 core。

## 同学 A：算法、指令语义、FFT 映射

A 主要负责从“程序和算法为什么能在这个 MCU 上跑”去讲，不负责系统架构图和逐行 VHDL。

主责内容：

- FFT 算法大概怎么被拆成指令序列。
- 为什么 FFT 适合多核并行，四个 worker 为什么能协作。
- 每类指令的含义和用途，例如 `MOV`、`LDR`、`STR`、`SADD16`、`SSUB16`、`SSAX`、`SMUAD`、`SMUSD`、`ASR`、`PKHBT`。
- 为什么这些指令足够支持 FFT 计算：搬数据、打包、加减、半字并行运算、乘加、移位缩放。
- 从程序角度说明“FFT 是 workload，不是硬连线专用逻辑”。
- 能读懂 `asm/mcu4_fft_workers_cnt22.s` 和 `asm/mcu4_basic_selftest.s` 里每条指令大概在做什么。

A 不主责：

- 系统全局架构图和模块边界划分。
- `mcu4_worker_core.vhd` 的状态机细节。
- ILA 具体抓哪些信号。
- Vivado 文件添加、IP 配置、时序报告细节。

A 应准备回答的问题：

- 你们为什么说这是 MCU，而不是 FFT 专用硬件？
- FFT 程序为什么需要这些 DSP 指令？
- `SMUAD`、`SMUSD` 在 FFT 里大概解决什么问题？
- `SADD16`、`SSUB16` 和普通 `ADD/SUB` 有什么区别？
- 四个 core 是怎么从算法层面分担任务的？
- 如果把 FFT 指令换成排序程序，理论上还能不能跑？
- 基础指令测试里每条指令的预期结果是什么？

推荐阅读：

- `docs/ASSEMBLY_LISTING.md`
- `docs/MCU_GENERALITY_REQUIREMENTS.md`
- `asm/mcu4_fft_workers_cnt22.s`
- `asm/mcu4_basic_selftest.s`

## 同学 B：worker 执行核心、写回、多周期 DSP

B 负责最核心的执行引擎，但范围要收窄：重点看单个 worker 怎么执行指令，不负责板级、四核外层和完整测试体系。

主责内容：

- `mcu4_worker_core.vhd` 如何执行一条指令。
- fetch、decode、run、多周期 DSP 状态之间怎么流动。
- PC、instruction、寄存器堆、执行单元、写回路径之间的数据流。
- 寄存器堆在哪里，写回信号如何产生。
- `LDR/STR` 如何访问 `dmem_bank0/dmem_bank1`。
- 多周期 DSP 怎么体现，为什么 `SMUAD/SMUSD` 不是简单一拍完成。
- 双发射/配对执行的代码入口在哪里，比如 3-bit `WPAIR_*_CODE`、`pair_kind`、`set_exec_pair_kind`。
- 为什么双发射是通用机制，而不是针对 FFT 某几条指令硬写死。
- `mcu4_worker_decoder.vhd` 的基本输入输出：32-bit 指令如何变成内部 op、寄存器编号和立即数。

B 不主责：

- 四个 worker 如何在 `mcu4_multicycle_core.vhd` 里组合。
- `board_top.vhd`、`mcu_fft_system.vhd`、Vivado、ILA 和时序报告。
- 完整 FFT 算法推导和每条汇编指令的算法意义。
- `mcu4_worker_instr_rom.vhd` 里所有 ROM 常量逐条解释。

B 应准备回答的问题：

- `mcu4_worker_core` 这个文件整体怎么工作？
- 一条 `MOV r5, #1` 从取指到写回经历了哪些路径？
- 寄存器堆什么时候被写入？
- `LDR` 读的是哪里，`STR` 写的是哪里？
- 多周期 DSP 状态机有哪些状态，解决了什么时序或资源问题？
- 你们说有双发射，代码里具体在哪里体现？
- 双发射会不会只对 FFT 有效？
- 如果连续两条普通 `MOV`，是不是也能被配对？
- `SMUAD/SMUSD` 为什么要进入 DSP 多周期状态？
- 指令格式解析是什么？

推荐阅读：

- `rtl/mcu4_worker_core.vhd`
- `rtl/mcu4_worker_decoder.vhd`
- `docs/WORKER_TIMING_AUDIT.md`

## 同学 C：全局架构、板级、集成、测试验证

C 负责把工程“整体长什么样、怎么跑起来、怎么证明正确、怎么上板展示”讲清楚。A 的全局架构压力转给 C，B 的外围集成压力也转给 C。

主责内容：

- 全局架构：指令 ROM、四个 worker、寄存器堆、ALU/DSP、`dmem_bank0/dmem_bank1`、board wrapper、ILA。
- `mcu4_multicycle_core.vhd` 如何例化 4 个 worker，`ACTIVE_CORES` 如何决定启用数量。
- `dmem_bank0/dmem_bank1` 在外层如何连接到 worker，为什么 FFT 程序会把它们当作阶段之间的工作区。
- `mcu4_multi_pkg.vhd` 中关键类型的意义，例如 `word_t`、`reg_file_t`、`program_rom_t`。
- `mcu4_worker_instr_rom.vhd` 从工程角度存放哪些程序：FFT 程序和基础测试程序。
- `board_top.vhd` 是板级入口，负责连接时钟、ROM、RAM、ILA 和系统 wrapper。
- `mcu_fft_system.vhd` 如何把输入 ROM 数据喂给 core，再把结果写入 verify RAM。
- `PROGRAM_ID` 和 `ACTIVE_CORES` 在哪里配置、如何影响运行模式。
- FFT 模式和基础指令测试模式的区别。
- 为什么基础指令展示最好新增一个 `board_top_basic` 或类似 top，直接抓 core 的通用执行/写回信号。
- 基础指令测试不应该每条指令都拉一个专用寄存器信号，而应该使用通用 trace：`pc_debug`、`instr_debug`、寄存器写回、存储写入、halt/illegal。
- testbench 如何证明正确，哪些 testbench 对应哪些层级。
- Vivado 工程需要加入哪些 VHDL 文件、约束文件和 IP。
- 170 MHz implementation 时序报告说明什么。

C 应准备回答的问题：

- 你们的系统架构有哪些元件？各自负责什么？
- 四核是在哪里实例化的？每个核是不是独立取自己的指令？
- `dmem_bank0/dmem_bank1` 和传统 MCU 的数据存储器是什么关系？
- `board_top` 和 `mcu_fft_system` 分别负责什么？
- 数据从 test ROM 到 core，再到 verify RAM 的流程是什么？
- 现在的 ILA 抓的是 FFT 输出流程，基础指令测试为什么需要换一组更合适的信号？
- 基础指令全部测试时，为什么不需要把 `r0-r15` 都拉出来？
- 如何通过结果区或写回 trace 证明 `MOV/LDR/STR/ADD/DSP` 等指令执行正确？
- Vivado 里应该添加哪些源码文件？
- `PROGRAM_ID=0/1` 和 `ACTIVE_CORES=1/4` 分别代表什么？
- 170 MHz 能过 implementation 时序说明了什么，最坏路径大概在哪里？

推荐阅读：

- `docs/README.md`
- `ARM_COMPLIANT_MULTICORE_ARCHITECTURE.md`
- `rtl/mcu4_multi_pkg.vhd`
- `rtl/mcu4_worker_instr_rom.vhd`
- `rtl/mcu4_multicycle_core.vhd`
- `rtl/board_top.vhd`
- `rtl/mcu_fft_system.vhd`
- `tb/*.vhd`
- `docs/VIVADO_BOARD_GUIDE.md`
- `timing_report_170MHz.txt`

## 综合问题接力方式

老师的问题通常不会完全属于一个人。建议按“谁主责谁先答，其他人补充”的方式接力：

| 老师问题 | 主答 | 补充 1 | 补充 2 |
| --- | --- | --- | --- |
| 指令格式和编码规则是什么？ | A：说明是 32-bit、ARM-like、支持哪些指令、每类指令用途 | B：说明 decoder 如何取字段并生成内部操作 | C：说明指令常量存在哪里，`PROGRAM_ID` 如何选择程序 |
| 你们的架构有哪些元件？ | C：画总图，解释 ROM、四核、寄存器堆、ALU/DSP、数据内存 bank、板级 wrapper | B：解释单个 worker 内部执行数据通路 | A：说明这些元件如何服务 FFT 程序 |
| 多周期体现在哪里？ | B：指出 DSP 状态机和写回路径 | A：说明 DSP 指令为什么计算更复杂 | C：说明 testbench 和时序报告如何验证 |
| 双发射体现在哪里？ | B：指出 3-bit `pair_kind` 预译码和配对执行入口 | A：说明连续可配对指令可以提高吞吐 | C：说明这不是 FFT 专用，基础指令也可观察 |
| 为什么不是专用 FFT 硬件？ | A：说明 FFT 只是 ROM 里的程序 | B：说明 core 按 decoder 输出执行通用操作 | C：说明可以切换 `PROGRAM_ID`，也可以做基础指令 ILA 展示 |
| 基础指令怎么验证？ | C：说明用 testbench、结果区和 ILA trace 展示 | A：说明每条指令的语义和预期结果 | B：说明写回/访存路径如何产生结果 |
| 四核和参数在哪里体现？ | C：说明 `ACTIVE_CORES`、`PROGRAM_ID` 和外层例化 | B：说明 worker 只按本地指令执行 | A：说明 FFT 程序如何利用多核 |

## 最小复习目标

答辩前每个人至少准备一段 2 分钟说明：

- A：从算法和 ISA 角度讲“为什么这些指令能跑 FFT，FFT 为什么只是程序”。
- B：从 worker core 角度讲“一条指令如何从取指、译码、执行到写回”。
- C：从全局架构、板级和验证角度讲“系统由哪些元件组成，工程如何上板运行，如何证明结果”。

这样分工后，A 专注算法和指令语义；B 专注单 worker 执行核心；C 负责全局架构、四核集成、板级、验证、参数和展示。三个人都能接住综合问题，但不会把所有压力堆到一个人身上。
