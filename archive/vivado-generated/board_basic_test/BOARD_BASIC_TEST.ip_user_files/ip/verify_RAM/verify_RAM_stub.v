// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:57:14 2026
// Host        : huancheng running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               e:/Digital_Exp/MCU_v1/BOARD_BASIC_TEST/BOARD_BASIC_TEST.gen/sources_1/ip/verify_RAM/verify_RAM_stub.v
// Design      : verify_RAM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k160tffg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *)
module verify_RAM(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[5:0],dina[15:0],douta[15:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [5:0]addra;
  input [15:0]dina;
  output [15:0]douta;
endmodule
