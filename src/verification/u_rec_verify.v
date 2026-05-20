`timescale 1ns/1ps
`default_nettype none

module U_REC (
    input  wire       sys_clk,        
    input  wire       baud_clk_16x,  
    input  wire       sys_rst_l,
    input  wire       uart_REC_dataH,
    output reg  [7:0] rec_dataH,
    output reg        rec_readyH,
    output reg        rec_busy
);

    
    reg sync1, sync2;

    always @(posedge sys_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            sync1 <= 1'b1;
            sync2 <= 1'b1;
        end
        else begin
            sync1 <= uart_REC_dataH;
            sync2 <= sync1;           
        end
    end

    wire rx_data = sync2;   


    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] rx_shift;

    always @(posedge sys_clk or negedge sys_rst_l) begin
        if (!sys_rst_l) begin
            state      <= IDLE;
            rec_dataH  <= 8'd0;
            rec_readyH <= 1'b0;
            rec_busy   <= 1'b0;
            tick_cnt   <= 0;
            bit_cnt    <= 0;
            rx_shift   <= 0;
        end
        else begin
    
            rec_readyH <= 1'b0;

            case (state)

                IDLE: begin
                    rec_busy <= 1'b0;
                    tick_cnt <= 0;
                    bit_cnt  <= 0;
                    rec_readyH <= 1'b1;

                    if (rx_data == 1'b0) begin
                        state    <= START;
                        rec_busy <= 1'b1;
                    end
                end

                
                START: begin
                    if (baud_clk_16x) begin
                        if (tick_cnt == 7) begin
                            tick_cnt <= 0;
                            if (rx_data == 1'b0)
                                state <= DATA;    
                            else
                                state <= IDLE;    
                        end
                        else begin
                            tick_cnt <= tick_cnt + 1;
                        end
                    end
                end

                
                DATA: begin
                    if (baud_clk_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt          <= 0;
                            rx_shift[bit_cnt] <= rx_data;   
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
                    if (baud_clk_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= IDLE;
                            rec_busy <= 1'b0;
                            if (rx_data == 1'b1) begin
                                rec_dataH  <= rx_shift;
                                rec_readyH <= 1'b1;  
                            end
                          
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
