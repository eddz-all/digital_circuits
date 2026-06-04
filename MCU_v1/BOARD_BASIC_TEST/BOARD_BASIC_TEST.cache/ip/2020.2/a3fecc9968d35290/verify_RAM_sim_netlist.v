// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:57:13 2026
// Host        : huancheng running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ verify_RAM_sim_netlist.v
// Design      : verify_RAM
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k160tffg676-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "verify_RAM,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
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
