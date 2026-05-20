`include "inc.h"
`default_nettype none
module u_xmit( 
    input wire sys_rst_l, xmitH, uart_clk, 
    input wire [`WORD_LEN-1:0]xmit_dataH,
    output reg xmit_active, xmit_doneH, uart_xmit_dataH
    );
        
reg[2:0]ps,ns;
localparam S_IDLE=0;
localparam S_START=1;
localparam S_DATA=2;
localparam S_STOP=3;
localparam S_DONE=4;

reg [3:0]count;
reg [$clog2(`WORD_LEN)-1:0]bit_count;
reg [`WORD_LEN-1:0]data;
    
    //CURRENT STATE LOGIC
    always@(posedge uart_clk or negedge sys_rst_l) begin
        if(!sys_rst_l) begin //NEGEDGE RST
            ps <= S_IDLE;
            
            count<=4'd0;
            bit_count<=0;
            data<={`WORD_LEN{1'b0}};
        end
        
        else begin
            ps <= ns;
            
            //4-BIT COUNTER LOGIC 
            if(ps==S_DATA || ps==S_START || ps==S_STOP) begin
                count<=count+1;
            end
            else begin
                count<=0;
            end
            
            //BIT COUNT LOGIC FOR TRANSMITTING 1-BIT DATA 
            if(ps==S_IDLE && xmitH) begin 
                data <= xmit_dataH;         //PARELLEL DATA STORED IN SHIFT REGISTER
                bit_count <= 1'b0;
            end
            else if(ps==S_DATA && count==4'd15) begin
                data <= data>>1;            //RIGHT SHIFTING TO EXTRACT EACH BIT THROUGH LSB
                bit_count <= bit_count+1;   //BIT COUNT INCREMENTED TILL IT REACHES 7
            end
            else begin
                data <= data;
                bit_count <= bit_count;
            end
        end
    end
                          
    //NEXT STATE LOGIC
    always@(*) begin
        xmit_active=1'b0;
        xmit_doneH=1'b0;
        uart_xmit_dataH=1'b1;
        
        case(ps) 
            S_IDLE: begin                   //WAITING FOR START BIT TO BE HIGH
                xmit_doneH=1'b1;
                if(xmitH) begin
                    ns=S_START;
                end
                else ns=S_IDLE;
            end
            
            S_START: begin                  //OUTPUT BIT WILL BE LOW FOR 1 CYCLE
                uart_xmit_dataH=1'b0;       //START BIT;
                xmit_active=1'b1;
                if(count==4'd15) begin
                    ns=S_DATA;                   
                end
                else begin
                    ns=S_START;
                end
            end
            
            S_DATA: begin                   //SERIAL OUTPUT IS RECEIVED 
                uart_xmit_dataH=data[0];
                xmit_active=1'b1;
                
                if(count==4'd15) begin
                    if(bit_count==`WORD_LEN-1) ns=S_STOP;
                    else ns=S_DATA;
                end
                else begin
                    ns=S_DATA;                   
                end
            end
            
            S_STOP: begin                   //OUTPUT IS MADE HIGH FOR 1 CYCLE ONCE ALL DATA BITS ARE RECEIVED 
                xmit_active=1'b1;
                uart_xmit_dataH=1'b1;       //STOP BIT
                if(count==4'd15) begin
                    ns=S_DONE;                   
                end
                else begin
                    ns=S_STOP;                
                end
            end
            
            S_DONE:  begin                  
                xmit_doneH=1'b1;
                ns=S_IDLE;
            end
            
            default: ns=S_IDLE;
        endcase
    end
endmodule
