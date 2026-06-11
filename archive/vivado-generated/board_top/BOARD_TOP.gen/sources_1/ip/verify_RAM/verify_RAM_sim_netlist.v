// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:32:16 2026
// Host        : huancheng running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               e:/Digital_Exp/MCU_v1/BOARD_TOP/BOARD_TOP.gen/sources_1/ip/verify_RAM/verify_RAM_sim_netlist.v
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
ENTM
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
