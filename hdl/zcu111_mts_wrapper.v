//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
//Date        : Mon Jan 22 15:35:41 2024
//Host        : ASCPHY-NC196428 running 64-bit major release  (build 9200)
//Command     : generate_target zcu111_mts_wrapper.bd
//Design      : zcu111_mts_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module zcu111_mts_wrapper
   (
    // input AXI4-Streams to the ADC BRAM capture
    S_AXIS_0_tdata,
    S_AXIS_0_tready,
    S_AXIS_0_tvalid,
    S_AXIS_1_tdata,
    S_AXIS_1_tready,
    S_AXIS_1_tvalid,
    S_AXIS_2_tdata,
    S_AXIS_2_tready,
    S_AXIS_2_tvalid,
    S_AXIS_3_tdata,
    S_AXIS_3_tready,
    S_AXIS_3_tvalid,
    
    Vp_Vn_0_v_n,
    Vp_Vn_0_v_p,
    // adc stuff
    adc0_clk_0_clk_n,
    adc0_clk_0_clk_p,
    adc1_clk_0_clk_n,
    adc1_clk_0_clk_p,
    adc2_clk_0_clk_n,
    adc2_clk_0_clk_p,
    adc3_clk_0_clk_n,
    adc3_clk_0_clk_p,
    m00_axis_0_tdata,
    m00_axis_0_tready,
    m00_axis_0_tvalid,
    m02_axis_0_tdata,
    m02_axis_0_tready,
    m02_axis_0_tvalid,
    m10_axis_0_tdata,
    m10_axis_0_tready,
    m10_axis_0_tvalid,
    m12_axis_0_tdata,
    m12_axis_0_tready,
    m12_axis_0_tvalid,
    m20_axis_0_tdata,
    m20_axis_0_tready,
    m20_axis_0_tvalid,
    m22_axis_0_tdata,
    m22_axis_0_tready,
    m22_axis_0_tvalid,
    m30_axis_0_tdata,
    m30_axis_0_tready,
    m30_axis_0_tvalid,
    m32_axis_0_tdata,
    m32_axis_0_tready,
    m32_axis_0_tvalid,
    // dac stuff. These are in the div2 clock domain
    dac1_clk_0_clk_p,
    dac1_clk_0_clk_n,
    s12_axis_0_tdata,
    s12_axis_0_tready,
    s12_axis_0_tvalid,
    s13_axis_0_tdata,
    s13_axis_0_tready,
    s13_axis_0_tvalid,    
    
    s_axi_aclk_0,
    s_axi_aresetn_0,
    s_axis_aclk_0,
    s_axis_aresetn_0,
    sysref_in_0_diff_n,
    sysref_in_0_diff_p,
    user_sysref_adc_0,
    // adc
    vin0_01_0_v_n,
    vin0_01_0_v_p,
    vin0_23_0_v_n,
    vin0_23_0_v_p,
    vin1_01_0_v_n,
    vin1_01_0_v_p,
    vin1_23_0_v_n,
    vin1_23_0_v_p,
    vin2_01_0_v_n,
    vin2_01_0_v_p,
    vin2_23_0_v_n,
    vin2_23_0_v_p,
    vin3_01_0_v_n,
    vin3_01_0_v_p,
    vin3_23_0_v_n,
    vin3_23_0_v_p,
    // dac
    vout12_0_v_p,
    vout12_0_v_n,
    vout13_0_v_p,
    vout13_0_v_n,

    // uart
    UART_rxd,
    UART_txd,    
    
    clk_adc0_0,
    pl_clk0,
    pl_resetn0
    );
  input [127:0]S_AXIS_0_tdata;
  output S_AXIS_0_tready;
  input S_AXIS_0_tvalid;
  input [127:0]S_AXIS_1_tdata;
  output S_AXIS_1_tready;
  input S_AXIS_1_tvalid;
  input [127:0]S_AXIS_2_tdata;
  output S_AXIS_2_tready;
  input S_AXIS_2_tvalid;
  input [127:0]S_AXIS_3_tdata;
  output S_AXIS_3_tready;
  input S_AXIS_3_tvalid;
  input Vp_Vn_0_v_n;
  input Vp_Vn_0_v_p;
  input adc0_clk_0_clk_n;
  input adc0_clk_0_clk_p;
  input adc1_clk_0_clk_n;
  input adc1_clk_0_clk_p;
  input adc2_clk_0_clk_n;
  input adc2_clk_0_clk_p;
  input adc3_clk_0_clk_n;
  input adc3_clk_0_clk_p;
  output [127:0]m00_axis_0_tdata;
  input m00_axis_0_tready;
  output m00_axis_0_tvalid;
  output [127:0]m02_axis_0_tdata;
  input m02_axis_0_tready;
  output m02_axis_0_tvalid;
  output [127:0]m10_axis_0_tdata;
  input m10_axis_0_tready;
  output m10_axis_0_tvalid;
  output [127:0]m12_axis_0_tdata;
  input m12_axis_0_tready;
  output m12_axis_0_tvalid;
  output [127:0]m20_axis_0_tdata;
  input m20_axis_0_tready;
  output m20_axis_0_tvalid;
  output [127:0]m22_axis_0_tdata;
  input m22_axis_0_tready;
  output m22_axis_0_tvalid;
  output [127:0]m30_axis_0_tdata;
  input m30_axis_0_tready;
  output m30_axis_0_tvalid;
  output [127:0]m32_axis_0_tdata;
  input m32_axis_0_tready;
  output m32_axis_0_tvalid;
  input s_axi_aclk_0;
  input s_axi_aresetn_0;
  input s_axis_aclk_0;
  input s_axis_aresetn_0;
  input sysref_in_0_diff_n;
  input sysref_in_0_diff_p;
  input user_sysref_adc_0;
  input vin0_01_0_v_n;
  input vin0_01_0_v_p;
  input vin0_23_0_v_n;
  input vin0_23_0_v_p;
  input vin1_01_0_v_n;
  input vin1_01_0_v_p;
  input vin1_23_0_v_n;
  input vin1_23_0_v_p;
  input vin2_01_0_v_n;
  input vin2_01_0_v_p;
  input vin2_23_0_v_n;
  input vin2_23_0_v_p;
  input vin3_01_0_v_n;
  input vin3_01_0_v_p;
  input vin3_23_0_v_n;
  input vin3_23_0_v_p;

  input UART_rxd;
  output UART_txd;
  
  output pl_clk0;
  output pl_resetn0;
  output clk_adc0_0;
  
  input dac1_clk_0_clk_p;
  input dac1_clk_0_clk_n;
  
  input [255:0] s12_axis_0_tdata;
  input         s12_axis_0_tvalid;
  output        s12_axis_0_tready;
  input [255:0] s13_axis_0_tdata;
  input         s13_axis_0_tvalid;
  output        s13_axis_0_tready;
  
  output vout12_0_v_p;
  output vout12_0_v_n;
  output vout13_0_v_p;
  output vout13_0_v_n;
  

  wire [127:0]S_AXIS_0_tdata;
  wire S_AXIS_0_tready;
  wire S_AXIS_0_tvalid;
  wire [127:0]S_AXIS_1_tdata;
  wire S_AXIS_1_tready;
  wire S_AXIS_1_tvalid;
  wire [127:0]S_AXIS_2_tdata;
  wire S_AXIS_2_tready;
  wire S_AXIS_2_tvalid;
  wire [127:0]S_AXIS_3_tdata;
  wire S_AXIS_3_tready;
  wire S_AXIS_3_tvalid;
  wire Vp_Vn_0_v_n;
  wire Vp_Vn_0_v_p;
  wire adc0_clk_0_clk_n;
  wire adc0_clk_0_clk_p;
  wire adc1_clk_0_clk_n;
  wire adc1_clk_0_clk_p;
  wire adc2_clk_0_clk_n;
  wire adc2_clk_0_clk_p;
  wire adc3_clk_0_clk_n;
  wire adc3_clk_0_clk_p;
  wire [127:0]m00_axis_0_tdata;
  wire m00_axis_0_tready;
  wire m00_axis_0_tvalid;
  wire [127:0]m02_axis_0_tdata;
  wire m02_axis_0_tready;
  wire m02_axis_0_tvalid;
  wire [127:0]m10_axis_0_tdata;
  wire m10_axis_0_tready;
  wire m10_axis_0_tvalid;
  wire [127:0]m12_axis_0_tdata;
  wire m12_axis_0_tready;
  wire m12_axis_0_tvalid;
  wire [127:0]m20_axis_0_tdata;
  wire m20_axis_0_tready;
  wire m20_axis_0_tvalid;
  wire [127:0]m22_axis_0_tdata;
  wire m22_axis_0_tready;
  wire m22_axis_0_tvalid;
  wire [127:0]m30_axis_0_tdata;
  wire m30_axis_0_tready;
  wire m30_axis_0_tvalid;
  wire [127:0]m32_axis_0_tdata;
  wire m32_axis_0_tready;
  wire m32_axis_0_tvalid;
  wire s_axi_aclk_0;
  wire s_axi_aresetn_0;
  wire s_axis_aclk_0;
  wire s_axis_aresetn_0;
  wire sysref_in_0_diff_n;
  wire sysref_in_0_diff_p;
  wire user_sysref_adc_0;
  wire vin0_01_0_v_n;
  wire vin0_01_0_v_p;
  wire vin0_23_0_v_n;
  wire vin0_23_0_v_p;
  wire vin1_01_0_v_n;
  wire vin1_01_0_v_p;
  wire vin1_23_0_v_n;
  wire vin1_23_0_v_p;
  wire vin2_01_0_v_n;
  wire vin2_01_0_v_p;
  wire vin2_23_0_v_n;
  wire vin2_23_0_v_p;
  wire vin3_01_0_v_n;
  wire vin3_01_0_v_p;
  wire vin3_23_0_v_n;
  wire vin3_23_0_v_p;

  zcu111_mts zcu111_mts_i
       (.S_AXIS_0_tdata(S_AXIS_0_tdata),
        .S_AXIS_0_tready(S_AXIS_0_tready),
        .S_AXIS_0_tvalid(S_AXIS_0_tvalid),
        .S_AXIS_1_tdata(S_AXIS_1_tdata),
        .S_AXIS_1_tready(S_AXIS_1_tready),
        .S_AXIS_1_tvalid(S_AXIS_1_tvalid),
        .S_AXIS_2_tdata(S_AXIS_2_tdata),
        .S_AXIS_2_tready(S_AXIS_2_tready),
        .S_AXIS_2_tvalid(S_AXIS_2_tvalid),
        .S_AXIS_3_tdata(S_AXIS_3_tdata),
        .S_AXIS_3_tready(S_AXIS_3_tready),
        .S_AXIS_3_tvalid(S_AXIS_3_tvalid),
        .Vp_Vn_0_v_n(Vp_Vn_0_v_n),
        .Vp_Vn_0_v_p(Vp_Vn_0_v_p),
        .adc0_clk_0_clk_n(adc0_clk_0_clk_n),
        .adc0_clk_0_clk_p(adc0_clk_0_clk_p),
        .adc1_clk_0_clk_n(adc1_clk_0_clk_n),
        .adc1_clk_0_clk_p(adc1_clk_0_clk_p),
        .adc2_clk_0_clk_n(adc2_clk_0_clk_n),
        .adc2_clk_0_clk_p(adc2_clk_0_clk_p),
        .adc3_clk_0_clk_n(adc3_clk_0_clk_n),
        .adc3_clk_0_clk_p(adc3_clk_0_clk_p),
        .m00_axis_0_tdata(m00_axis_0_tdata),
        .m00_axis_0_tready(m00_axis_0_tready),
        .m00_axis_0_tvalid(m00_axis_0_tvalid),
        .m02_axis_0_tdata(m02_axis_0_tdata),
        .m02_axis_0_tready(m02_axis_0_tready),
        .m02_axis_0_tvalid(m02_axis_0_tvalid),
        .m10_axis_0_tdata(m10_axis_0_tdata),
        .m10_axis_0_tready(m10_axis_0_tready),
        .m10_axis_0_tvalid(m10_axis_0_tvalid),
        .m12_axis_0_tdata(m12_axis_0_tdata),
        .m12_axis_0_tready(m12_axis_0_tready),
        .m12_axis_0_tvalid(m12_axis_0_tvalid),
        .m20_axis_0_tdata(m20_axis_0_tdata),
        .m20_axis_0_tready(m20_axis_0_tready),
        .m20_axis_0_tvalid(m20_axis_0_tvalid),
        .m22_axis_0_tdata(m22_axis_0_tdata),
        .m22_axis_0_tready(m22_axis_0_tready),
        .m22_axis_0_tvalid(m22_axis_0_tvalid),
        .m30_axis_0_tdata(m30_axis_0_tdata),
        .m30_axis_0_tready(m30_axis_0_tready),
        .m30_axis_0_tvalid(m30_axis_0_tvalid),
        .m32_axis_0_tdata(m32_axis_0_tdata),
        .m32_axis_0_tready(m32_axis_0_tready),
        .m32_axis_0_tvalid(m32_axis_0_tvalid),
        .s_axi_aclk_0(s_axi_aclk_0),
        .s_axi_aresetn_0(s_axi_aresetn_0),
        .s_axis_aclk_0(s_axis_aclk_0),
        .s_axis_aresetn_0(s_axis_aresetn_0),
        .sysref_in_0_diff_n(sysref_in_0_diff_n),
        .sysref_in_0_diff_p(sysref_in_0_diff_p),
        .user_sysref_adc_0(user_sysref_adc_0),
        .vin0_01_0_v_n(vin0_01_0_v_n),
        .vin0_01_0_v_p(vin0_01_0_v_p),
        .vin0_23_0_v_n(vin0_23_0_v_n),
        .vin0_23_0_v_p(vin0_23_0_v_p),
        .vin1_01_0_v_n(vin1_01_0_v_n),
        .vin1_01_0_v_p(vin1_01_0_v_p),
        .vin1_23_0_v_n(vin1_23_0_v_n),
        .vin1_23_0_v_p(vin1_23_0_v_p),
        .vin2_01_0_v_n(vin2_01_0_v_n),
        .vin2_01_0_v_p(vin2_01_0_v_p),
        .vin2_23_0_v_n(vin2_23_0_v_n),
        .vin2_23_0_v_p(vin2_23_0_v_p),
        .vin3_01_0_v_n(vin3_01_0_v_n),
        .vin3_01_0_v_p(vin3_01_0_v_p),
        .vin3_23_0_v_n(vin3_23_0_v_n),
        .vin3_23_0_v_p(vin3_23_0_v_p),
        .clk_adc0_0(clk_adc0_0),
        .pl_clk0(pl_clk0),
        .pl_resetn0(pl_resetn0),
        .dac1_clk_0_clk_p(dac1_clk_0_clk_p),
        .dac1_clk_0_clk_n(dac1_clk_0_clk_n),
        .vout12_0_v_p(vout12_0_v_p),
        .vout12_0_v_n(vout12_0_v_n),
        .vout13_0_v_p(vout13_0_v_p),
        .vout13_0_v_n(vout13_0_v_n),
        .s12_axis_0_tdata(s12_axis_0_tdata),
        .s12_axis_0_tvalid(s12_axis_0_tvalid),
        .s12_axis_0_tready(s12_axis_0_tready),
        .s13_axis_0_tdata(s13_axis_0_tdata),
        .s13_axis_0_tready(s13_axis_0_tready),
        .s13_axis_0_tvalid(s13_axis_0_tvalid),
        
        .UART_txd(UART_txd),
        .UART_rxd(UART_rxd)   
        );
endmodule
