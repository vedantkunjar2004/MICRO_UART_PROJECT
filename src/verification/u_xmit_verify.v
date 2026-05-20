`timescale 1ns/1ps
`default_nettype none

module U_TRANS (
    input  wire       sys_clk,       
    input  wire       baud_clk_16x,   
    input  wire       sys_rst_l,
    input  wire       xmitH,
    input  wire [7:0] xmit_dataH,
    output reg        uart_XMIT_dataH,
    output reg        xmit_doneH,
    output reg        xmit_active
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] tx_data;

    always @(posedge sys_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            state           <= IDLE;
            uart_XMIT_dataH <= 1'b1;
            xmit_doneH      <= 1'b0;
            xmit_active     <= 1'b0;
            tick_cnt        <= 0;
            bit_cnt         <= 0;
            tx_data         <= 0;
        end
        else begin
             xmit_doneH <= 1'b0;

            case (state)

                IDLE: begin
                    uart_XMIT_dataH <= 1'b1;   
                    xmit_active     <= 1'b0;
                    tick_cnt        <= 0;
                    bit_cnt         <= 0;
                    xmit_doneH      <=1'b1;
     
                    if (xmitH) begin
                        tx_data     <= xmit_dataH;
                        state       <= START;
                        xmit_active <= 1'b1;
                        xmit_doneH  <= 1'b0;
                    end
                end

                START: begin
                    uart_XMIT_dataH <= 1'b0;   

                    if (baud_clk_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= DATA;
                        end
                        else begin
                            tick_cnt <= tick_cnt + 1;
                        end
                    end
                end

                DATA: begin
                    uart_XMIT_dataH <= tx_data[bit_cnt];  
                    if (baud_clk_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            if (bit_cnt == 7) begin
                                bit_cnt <= 0;
                                state   <= STOP;
                            end
                            else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                        else begin
                            tick_cnt <= tick_cnt + 1;
                        end
                    end
                end

                STOP: begin
                    uart_XMIT_dataH <= 1'b1;  
                    if (baud_clk_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt    <= 0;
                            state       <= IDLE;
                            xmit_active <= 1'b0;
                            xmit_doneH  <= 1'b1;  
                        end
                        else begin
                            tick_cnt <= tick_cnt + 1;
                        end
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
