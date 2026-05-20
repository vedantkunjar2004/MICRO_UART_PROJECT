`timescale 1ns/1ps
`default_nettype none
module U_BAUD #(
    parameter integer SYS_CLK_FREQ = 50000000,
    parameter integer BAUD_RATE    = 9600
)(
    input  wire sys_clk,
    input  wire sys_rst_l,
    output reg  baud_clk_16x      
);
    localparam integer DIV = SYS_CLK_FREQ / (BAUD_RATE * 16);
    reg [$clog2(DIV)-1:0] count;
    always @(posedge sys_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            count        <= 0;
            baud_clk_16x <= 1'b0;
        end
        else begin
            if (count == DIV - 1) begin
                count        <= 0;
                baud_clk_16x <= 1'b1;   
            end
            else begin
                count        <= count + 1;
                baud_clk_16x <= 1'b0;   
            end
        end
    end

endmodule
