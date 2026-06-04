// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:30:29 2026
// Host        : huancheng running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ test_ROM_sim_netlist.v
// Design      : test_ROM
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k160tffg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "test_ROM,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
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
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_blk_mem_gen_v8_4_4 U0
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
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 20400)
`pragma protect data_block
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
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
