`include "inc.h"
`default_nettype none
module uart(
    input wire sys_clk, sys_rst_l, xmitH, uart_REC_dataH,
    input wire [`WORD_LEN-1:0]xmit_dataH,
    output wire uart_xmit_dataH, xmit_doneH, rec_readyH, rec_busy, xmit_active,
    output wire [`WORD_LEN-1:0]rec_dataH
    );
    
    wire uart_clk;
    
    baud b1(
    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst_l),
    .uart_clk(uart_clk)
    );
    
    u_xmit u1(
    .sys_rst_l(sys_rst_l),
    .xmitH(xmitH),
    .uart_clk(uart_clk),
    .xmit_dataH(xmit_dataH),
    .xmit_active(xmit_active),
    .xmit_doneH(xmit_doneH),
    .uart_xmit_dataH(uart_xmit_dataH)
    );
    
    u_rec u2(
    .sys_rst_l(sys_rst_l),
    .rec_readyH(rec_readyH),
    .uart_clk(uart_clk),
    .rec_busy(rec_busy),
    .rec_dataH(rec_dataH),
    .uart_REC_dataH(uart_REC_dataH)
    );
    
endmodule
