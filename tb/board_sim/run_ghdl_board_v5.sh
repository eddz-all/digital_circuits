#!/usr/bin/env sh
set -eu

GHDL_FLAGS="${GHDL_FLAGS:---std=08 -fsynopsys}"

ghdl -a $GHDL_FLAGS \
  rtl/00_mcu_v5_pkg.vhd \
  rtl/mcu_v5_instr_rom.vhd \
  rtl/mcu_v5_decoder.vhd \
  rtl/mcu_v5_alu.vhd \
  rtl/mcu_v5_regfile.vhd \
  rtl/mcu_v5_input_mem.vhd \
  rtl/mcu_v5_work_ram.vhd \
  rtl/mcu_v5_output_mem.vhd \
  rtl/mcu_v5_data_mem.vhd \
  rtl/mcu_v5_pc_unit.vhd \
  rtl/mcu_v5_core.vhd \
  rtl/mcu_fft_system.vhd \
  vivado/board_top/BOARD_TOP.srcs/sources_1/new/board_top.vhd \
  tb/board_sim/board_ip_models.vhd \
  tb/board_sim/board_top_tb.vhd

ghdl -e $GHDL_FLAGS board_top_tb
ghdl -r $GHDL_FLAGS board_top_tb --stop-time=20us
