// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:30:29 2026
// Host        : huancheng running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               e:/Digital_Exp/MCU_v1/BOARD_TOP/BOARD_TOP.gen/sources_1/ip/test_ROM/test_ROM_sim_netlist.v
// Design      : test_ROM
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k160tffg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "test_ROM,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module test_ROM
   (clka,
    ena,
    wea,
    addra,
    dina,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [0:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [5:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [15:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [15:0]douta;

  wire [5:0]addra;
  wire clka;
  wire [15:0]dina;
  wire [15:0]douta;
  wire ena;
  wire [0:0]wea;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [15:0]NLW_U0_doutb_UNCONNECTED;
  wire [5:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [5:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [15:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "6" *) 
  (* C_ADDRB_WIDTH = "6" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     2.7211 mW" *) 
  (* C_FAMILY = "kintex7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "test_ROM.mem" *) 
  (* C_INIT_FILE_NAME = "test_ROM.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "0" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "64" *) 
  (* C_READ_DEPTH_B = "64" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "16" *) 
  (* C_READ_WIDTH_B = "16" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "64" *) 
  (* C_WRITE_DEPTH_B = "64" *) 
  (* C_WRITE_MODE_A = "NO_CHANGE" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "16" *) 
  (* C_WRITE_WIDTH_B = "16" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  test_ROM_blk_mem_gen_v8_4_4 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[15:0]),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[5:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[5:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[15:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2020.2"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
QGLtnqZzRetDH6gCWT4Js6wuLlZfrNx/VJp3sfR2NF+cxypO5AxN0oDKLJJtmdrtE/ueNDg+Qf7Z
TqBNRojORA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
B6Ger3hRvfjHkaJ+W8639Kl3TzC9TogLuklOXEiMNdc4Im+DjEUzxb3DKlzu0VW3zxZqjJ3+wsW/
LnRmPCESi5Y9eRJaLFXg79EMfoj4X+nTdHAP6yCfltBADKegZ12gpnB/8ey5yn2KA74LUtPC7jna
iyjqSfsWLGnz6UdXzwk=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BX+DxgMPRyZbYojCUR9Sk8Lq+3ZigBz4yMFHQkmurfdfDzyTPJCE827eGiPyTenK1QPVhEtf9g06
0BFXq/0COPuU1BWJwdkz1c4dE6/exDwhvEh+hPx3vRY6z8fDEf6aGVIXrHDvrmddehe7yMSIpo+k
aXHR06EEdfHCFY4TggYwhcJVXjkE+ApsVuyfmEfPmYjo8hCWyQyBsUWIOY03q1+MvUjjsmTwgs9g
fh5MY9ToaLfoJxPKdCpsqrBX4LJ+VDGFlAqIcqHTE2jCmPiToZAFXB7fzf1wDjFCBlJyFVDBGi0i
m+CouLSb7X1mvVhdDZgNrZDJMV688Bu3o54vew==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DaIU/Ddc8USbZ2mURzujJDWDH1JbHl5tFVOOQ2aVaUPIA71yyE38OXVLEtF8rNmujYH30nEeQ+FV
LVJ16aaHw+iiuaqorTM3K5KLohVlN+WlcEtSXHuPNHjw8ddqtzpaX7pH1zqZH+YmfCL5oaNLqDH4
rkBnUl0/Gm/hzSwKjYhXGQFYQ+gGP99OjXakzrAqZzp/Iq4gt+Z5902/JV9thd/isHQImJ0QyK8M
EKM579iPAfXGes2mbiNYHcvDmSPYmW1zlhOE++N1EKeea7j/msnKeyhlC+hGE4Xfn4TVvqgQexCT
rp/wS/MosY6WH1aKFQlFH2hEppA7KXUaQlvG+w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
XmWoAt4X8hrCJ5yTyug4ajJW5UhfkLNibzjihWzZ4Cr9hQSvWZoTc8rjGsLPbz6Le+/9iI5KxecS
eR0wiAO+G2IkwhZgVBeZdKoFnlnTVAyLjk9wMAFXNyJZM6b1NDbfXlPcUsC6JePvPlwwdWknkSsC
r3KvgkWAS+O3xvRmaNw=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hw3Y+rShKrXiUViyNU1/O2qv6TgheLHBnFMj1i9MUGrHYqh9pLfLYUgWR7S2vj4jv4S+Ks0BpP4p
dKEqVAFmTCfQNEUHaVcFPkOHgig6L4mhLY6HUUKJoRgiQepgLi/W3V+ZZPQSQFkB3CU4MsJzhXvR
yLcpDriZy8cnAHD87Zi5DrNGBzj3kigJeM0du6lCQbxtF5aEdoaNP+YTnIFtcqYhoYnswQlYt0sV
HKgFA8VzqzL5WYnpH7+1IKmFkJBHkyqHCa9wPK0qCKnxkuDj70YzPVqQ+cocdKU+/gNdpCOdZlci
F2HTxrgfrXndJru3TiDqu4UavqAe0MNuFp3t0w==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
XPVggoWL6aXz+MpODTOZhEUQDa0vfEnUDaYeEHXm2vGyqKJujN2c/FFAFBeBYdJATLsIsQ+BqoPc
pBbcFYXDBfOtFIW2dH6Y1OoD65KyJ/hAq8coa21kFgq4hFat5vzZ2iIfkCpTUr4vDZO7Xne8cZO9
WsHffoTCt5rS59wWm2b8I5R8Eh2TUbQg3RCyrcnD66cvcEnlXe1CNMQ4/loVJpA4IBinBf820Wjc
vw2fZbGI0jXC+ACSHOviH63Xwmn+aRV5Ppkup7IYoon/ieKapRQeASu3TTY37xSBXiInSdtMTzJ6
+4GfO4eSHVriCk/sWbuTBzfRzoSShrnHjzz5LA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2020_08", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
L78XuiswVcgO2gtebzL7SA9BC/jJGAM0v6S9pzmyqL+QYzRneiYeGyDmsW33jEVVSTuNjTXkBLY7
yTOKQruatwe4V0OLi6174saSAmPgerSV1GyLP7KhmusLV/N61avC9TPam+tekhKeE0tds4EnJ3et
4JdLh+SE4Z4pcuqCjB5MFneIYKKWDx7siU6oesAQtoSJOesfMchX63MhOjOHFP/ch+1gHv3T45hg
IGF7V7TrdREVE4f9631tlVJ1o2Dypsmo/76Itz5WCGlTMjAnWXN8IXxKN+PZ3dyt1wjrZm2P/td+
xiGszFnSLrRvw/HferwtSmRx8q0fiHZ88roGTw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kDX5kq2QEe25429T6vQqBCFvV1McKTJRYfK99ymVNK2GGvGLXSzgwJHwB2fj9rM0wme3zYYY0vQR
x+9F4L7KLlOVY6qY3LB59uDzyXBI3mMZaS905HXHJkdZHWtQWpfHhl27LqL+8FSluaD6F+KFfYOV
CwIOVuCIp/XjxFXpNBik7YiPt4kHOlDA97IXNLnYUn/g1csGqeNWce4UTne50ggWvLYGbTFGmTjT
N67TpUiGRVRCSv8Tax72GWFIMFZk3Tlp68ZUSQEybZMWX1U9XdMdtxfvNGhf8mi5jQJ2SupSzKu4
T/+53IN9T8aLePAiGBKKG1ZBj4y1ZyYA7XYvjw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 20320)
`pragma protect data_block
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
evVuERBODuWx7vP9WGPGz5ha4QPUpHdeFk+G5w==
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
