`include "inc.h"
`default_nettype none
module baud(input wire sys_clk, sys_rst_l, output reg uart_clk);

reg [`CW-1:0]count;

always@(posedge sys_clk or negedge sys_rst_l) begin    
    if(!sys_rst_l) begin
        count<=0;
        uart_clk<=0;
    end
    else begin
        if(count==`CLK_DIV-1) begin
            uart_clk<=~uart_clk;
            count<=0;
        end
        else
            count<=count+1;
    end
end

endmodule
