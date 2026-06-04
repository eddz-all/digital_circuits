// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:57:14 2026
// Host        : huancheng running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               e:/Digital_Exp/MCU_v1/BOARD_BASIC_TEST/BOARD_BASIC_TEST.gen/sources_1/ip/verify_RAM/verify_RAM_sim_netlist.v
// Design      : verify_RAM
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k160tffg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "verify_RAM,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module verify_RAM
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
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     2.97835 mW" *) 
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
  (* C_INIT_FILE = "verify_RAM.mem" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
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
  (* C_WRITE_MODE_A = "READ_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "16" *) 
  (* C_WRITE_WIDTH_B = "16" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  verify_RAM_blk_mem_gen_v8_4_4 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 20352)
`pragma protect data_block
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
VCSp
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
