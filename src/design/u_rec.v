`default_nettype none
`include "inc.h"
module u_rec(
    input wire uart_clk, sys_rst_l, uart_REC_dataH,
    output reg rec_readyH, rec_busy, 
    output reg [`WORD_LEN-1:0]rec_dataH           
    );
    
reg[2:0]ps,ns;
localparam S_IDLE=0;
localparam S_START=1;
localparam S_DATA=2;
localparam S_STOP=3;
localparam S_DONE=4;

reg [3:0]count;
reg [`WORD_LEN-1:0]temp_data = {`WORD_LEN{1'b0}};
reg [$clog2(`WORD_LEN)-1:0]bit_count;
reg sync1,sync2;

//2-FF SYNCHRONIZER
always@(posedge uart_clk or negedge sys_rst_l) begin
    if(!sys_rst_l) begin
        sync1 <= 1'b1;
        sync2 <= 1'b1;
    end
    else begin
        sync1 <= uart_REC_dataH;
        sync2 <= sync1;
    end
end

//CURRENT STATE LOGIC
always@(posedge uart_clk or negedge sys_rst_l) begin
    if(!sys_rst_l) begin
        ps<=S_IDLE;
        
        count<=1'b0;
        bit_count<=1'b0;
        temp_data<={`WORD_LEN{1'b0}};  
        rec_dataH<=0;      
    end
    else begin
        ps<=ns;
        
        
        //4-BIT COUNTER LOGIC
        if(ps==S_IDLE) count <= 4'd0;
        else if(ps==S_START && count==4'd7) count <= 4'd0;
        else if(ps==S_DATA && count==4'd15 && bit_count==`WORD_LEN-1) count <= 4'd0;
        else if(ps==S_START || ps==S_DATA || ps==S_STOP) count <= count+1;
        else count <= 4'd0;
            
       //BIT COUNT LOGIC
       if(ps==S_IDLE && !sync2) begin
            temp_data <= {`WORD_LEN{1'b0}};
            bit_count <= 0;
       end
       else if(ps==S_DATA && count==4'd15) begin
            temp_data <= {sync2, temp_data[`WORD_LEN-1:1]};
            if(bit_count==`WORD_LEN-1) bit_count <= 0;
            else bit_count <= bit_count+1;
       end
       else begin
            bit_count <= bit_count;
            temp_data <= temp_data;
       end
       
       if(ps==S_DONE && sync2) begin
            rec_dataH <= temp_data;
       end
       else rec_dataH <= rec_dataH;
    end    
end

//NEXT STATE LOGIC
always@(*) begin
    rec_readyH = 1'b1;
    rec_busy = 1'b0;
    
    case(ps)
        S_IDLE: begin
            if(!sync2) ns = S_START;
            else ns = S_IDLE;        
        end
        
        S_START: begin
            rec_busy=1'b1;
            rec_readyH=1'b0;
            
            if(count==7) begin
                if(sync2==1'b0) ns=S_DATA;
                else ns=S_IDLE;
            end
            else ns=S_START;
        end
        
        S_DATA:begin
            rec_busy=1'b1;
            rec_readyH=1'b0; 
            
            if(count==4'd15) begin
                if(bit_count==`WORD_LEN-1) begin
                    ns=S_STOP;
                end
                else 
                    ns=S_DATA;
            end
            else ns=S_DATA;
        end
        
        S_STOP: begin
            rec_busy = 1'b1;
            rec_readyH = 1'b0;
            
            if(count==4'd15) begin
                if(sync2) ns = S_DONE;
                else ns = S_IDLE;
            end
            else ns=S_STOP;           
        end
        
        S_DONE: begin
            ns = S_IDLE;  
            rec_readyH = 1'b1;
            rec_busy = 1'b0;          
        end
        
        default: begin
            ns = S_IDLE;
        end
    endcase
end

endmodule
