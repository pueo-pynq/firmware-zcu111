`timescale 1ns / 1ps
// MAX_XFER needs to be a power of 2
module adc_cap_x2 #(parameter DWIDTH_IN = 128,
                    parameter DWIDTH_OUT = 256,
                    parameter MAX_XFER = 2048,
                    parameter USE_DEBUG = 0)(
        input aclk,
        input aresetn,
        input [DWIDTH_IN-1:0] s_axis_tdata,
        input         s_axis_tvalid,
        output        s_axis_tready,
        
        input clk_i,
        input capture_i,
        output done_o,
        // this is a Xilinx BRAM interface
        (* X_INTERFACE_PARAMETER = "MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ, MEM_SIZE 32768, MEM_WIDTH 256" *)
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A DIN" *)
        output [DWIDTH_OUT-1:0] bram_wdata,
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A WE" *)
        output [(DWIDTH_OUT/8)-1:0]  bram_we,
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A EN" *)
        output         bram_en,
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A DOUT" *)
        input [DWIDTH_OUT-1:0]  bram_rdata,
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A ADDR" *)
        output [31:0]  bram_addr,
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A CLK" *)
        output         bram_clk,
        (* X_INTERFACE_INFO = "xilinx.com:interface:bram:1.0 BRAM_A RST" *)
        output         bram_rst        
    );

    localparam ADDR_BITS = $clog2(MAX_XFER);
    // use the carry out of the ripple counter to trip the end
    reg [ADDR_BITS-1:0] counter = {ADDR_BITS{1'b0}};
    // bit 0 = 8    0
    // bit 1 = 16   upshift 1
    // bit 2 = 32   upshift 2
    // bit 3 = 64   upshift 3
    // bit 4 = 128  upshift 4
    // bit 5 = 256  upshift 5
    wire [ADDR_BITS+5-1:0] this_addr = { counter, {5{1'b0}} };
    
    wire [ADDR_BITS:0] counter_plus_one = counter + 1;
    reg running = 0;
    reg [1:0] capture = 2'b00;
    reg start_capture = 0;

            
    // this module does a synchronous widen-and-transfer
    // there's no point to burn a block RAM.
    // NOTE: this module BLATANTLY IGNORES tvalid
    // because it's for a streaming input
        
    // we need a phase track for that.
    // slow clock toggles this
    reg slow_clk_phase = 0;
    // fast clock captures here
    reg fast_clk_phase = 0;
    // reregister
    reg fast_clk_phase_rereg = 0;
    // capture upper
    reg capture_upper = 0;
    // clk  clkx2   slow_clk_phase fast_clk_phase fast_clk_phase_rereg  capture_upper   din     din_store   dout
    // 0    0       0              1              1                     1               B       A           XX
    // 0    1       0              0              1                     0               C       A           BA
    // 1    2       1              0              0                     1               D       C           BA
    // 1    3       1              1              0                     0               E       C           DC
    // 2    4       0              1              1                     1               F       E           DC
    // 2    5       0              0              1                     0               G       E           FE
    reg [127:0] din_store = {128{1'b0}};
    reg [255:0] dout = {256{1'b0}};
    reg [255:0] dout_rereg = {256{1'b0}};

    always @(posedge aclk) begin
        fast_clk_phase_rereg <= fast_clk_phase;
        fast_clk_phase <= slow_clk_phase;
        capture_upper <= fast_clk_phase != fast_clk_phase_rereg;
        
        if (!capture_upper) din_store <= s_axis_tdata;
        // dout is only captured every other clock, so its data is stable
        // in the clk_div2 regime
        if (capture_upper) dout <= { s_axis_tdata, din_store };
    end
    
    always @(posedge clk_i) begin
        slow_clk_phase <= ~slow_clk_phase;

        dout_rereg <= dout;

        capture <= { capture[0], capture_i };
        start_capture <= capture[0] && !capture[1];
        
        if (start_capture) begin
            counter <= {ADDR_BITS{1'b0}};
        end else if (running) counter <= counter_plus_one[ADDR_BITS-1:0];
        
        if (start_capture) running <= 1;
        else if (counter_plus_one[ADDR_BITS]) running <= 0;
    end    
        
    assign bram_addr = this_addr;
    assign bram_we = {(DWIDTH_OUT/8){running}};
    assign bram_en = running;
    assign bram_wdata = dout_rereg;
    
    assign s_axis_tready = 1'b1;
    assign done_o = !running;
endmodule
