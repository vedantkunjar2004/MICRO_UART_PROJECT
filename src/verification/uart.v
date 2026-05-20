
`default_nettype none
module U_TOP #(
    parameter integer SYS_CLK_FREQ = 50000000,
    parameter integer BAUD_RATE    = 9600
)(
    input  wire       sys_clk,
    input  wire       sys_rst_l,

 
    input  wire       xmitH,
    input  wire [7:0] xmit_dataH,
    output wire       uart_XMIT_dataH,
    output wire       xmit_doneH,
    output wire       xmit_active,

   
    input  wire       uart_REC_dataH,
    output wire [7:0] rec_dataH,
    output wire       rec_readyH,
    output wire       rec_busy
);

    wire baud_clk_16x;
    U_BAUD #(
        .SYS_CLK_FREQ (SYS_CLK_FREQ),
        .BAUD_RATE    (BAUD_RATE)
    ) bg (
        .sys_clk     (sys_clk),
        .sys_rst_l   (sys_rst_l),
        .baud_clk_16x(baud_clk_16x)
    );

   
    U_TRANS tx (
        .sys_clk        (sys_clk),
        .baud_clk_16x   (baud_clk_16x),
        .sys_rst_l      (sys_rst_l),
        .xmitH          (xmitH),
        .xmit_dataH     (xmit_dataH),
        .uart_XMIT_dataH(uart_XMIT_dataH),
        .xmit_doneH     (xmit_doneH),
        .xmit_active    (xmit_active)
    );

    
    U_REC rx (
        .sys_clk       (sys_clk),
        .baud_clk_16x  (baud_clk_16x),
        .sys_rst_l     (sys_rst_l),
        .uart_REC_dataH(uart_REC_dataH),
        .rec_dataH     (rec_dataH),
        .rec_readyH    (rec_readyH),
        .rec_busy      (rec_busy)
    );

endmodule
