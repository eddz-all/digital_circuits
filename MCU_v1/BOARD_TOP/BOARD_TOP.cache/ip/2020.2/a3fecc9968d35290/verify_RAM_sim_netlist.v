// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Thu Jun  4 15:32:16 2026
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
