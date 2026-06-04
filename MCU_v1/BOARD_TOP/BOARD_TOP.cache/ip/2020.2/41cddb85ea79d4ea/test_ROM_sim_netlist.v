// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:26:35 2026
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
