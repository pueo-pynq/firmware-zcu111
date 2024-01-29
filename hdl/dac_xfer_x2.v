`timescale 1ns / 1ps
// Same as adc_cap_x2, just going the other way.
// DACs natively work at 1/16th so we need this to connect in/out
module dac_xfer_x2 #(parameter DWIDTH_IN=128,
                     parameter DWIDTH_OUT=256)(
        input aclk,
        input aresetn,
        // tvalid/tready here are just lies        
        input [DWIDTH_IN-1:0] s_axis_tdata,
        input                 s_axis_tvalid,
        output                s_axis_tready,
        
        input aclk_div2,        
        output [DWIDTH_OUT-1:0] m_axis_tdata,
        output                  m_axis_tvalid,
        input                   m_axis_tready        
    );
    
    reg slow_clk_phase = 0;
    reg fast_clk_phase = 0;
    reg fast_clk_phase_rereg = 0;
    reg capture_upper = 0;
    
    reg [127:0] din_store = {128{1'b0}};
    reg [255:0] dout = {256{1'b0}};
    reg [255:0] dout_rereg = {256{1'b0}};
    
    always @(posedge aclk) begin
        fast_clk_phase_rereg <= fast_clk_phase;
        fast_clk_phase <= slow_clk_phase;
        capture_upper <= fast_clk_phase != fast_clk_phase_rereg;
        
        if (!capture_upper) din_store <= s_axis_tdata;
        if (capture_upper) dout <= { s_axis_tdata, din_store };
    end
    always @(posedge aclk_div2) begin
        slow_clk_phase <= ~slow_clk_phase;
        dout_rereg <= dout;
    end
        
    assign m_axis_tvalid = 1'b1;
    assign m_axis_tdata = dout_rereg;
    
endmodule
