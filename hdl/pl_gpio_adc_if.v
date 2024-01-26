`timescale 1ns / 1ps
module pl_gpio_adc_if(
        input ps_clk,
        input adc_div2_clk,
        output [15:0] gpio_to_ps,
        input [15:0] gpio_from_ps,
        input [15:0] gpio_direction,
        
        output capture_o,
        input [7:0] done_i
    );
    
    (* CUSTOM_CC_SRC = "ACLKDIV2" *)
    reg [7:0] done_div2 = {8{1'b0}};
    (* CUSTOM_CC_DST = "PSCLK" *)
    reg [7:0] done_psclk = {8{1'b0}};
    
    reg [1:0] capture_reg = {2{1'b0}};
    reg capture_psclk = 0;
    always @(posedge ps_clk) begin
        capture_reg <= { capture_reg[0], gpio_from_ps[0] && !gpio_direction[0] };
        capture_psclk <= capture_reg[0] && !capture_reg[1];
        
        done_psclk <= done_div2;
    end
    
    always @(posedge adc_div2_clk) begin
        done_div2 <= done_i;
    end
    
    flag_sync u_sync(.in_clkA(capture_psclk),.out_clkB(capture_o),.clkA(ps_clk),.clkB(adc_div2_clk));
    
    assign gpio_to_ps = { done_psclk, {8{1'b0}} };
    
endmodule
