`timescale 1ns / 1ps
`default_nettype none
 
module main_tb_uart;
    reg sys_clk1, sys_clk2, sys_clk3;
    reg sys_rst_l;
    reg xmit_H;
    reg [7:0] xmit_dataH;
    wire uart_XMIT_dataH;
    wire xmit_active;
    wire xmit_doneH;
    wire rec_ready1, rec_busy1;
    wire rec_ready2, rec_busy2;
    wire rec_ready3, rec_busy3;
    wire [7:0] rec_dataH1, rec_dataH2, rec_dataH3;
 
    // ALL clocks must be 100MHz (#5 delay) to match the fixed CLK_DIV macro inside inc.h
    initial begin
        sys_clk1 = 0;
        forever #5 sys_clk1 = ~sys_clk1; 
    end
 
    initial begin
        sys_clk2 = 0;
        forever #5 sys_clk2 = ~sys_clk2; 
    end
 
    initial begin
        sys_clk3 = 0;
        forever #5 sys_clk3 = ~sys_clk3; 
    end
 
    // Dynamically derive the correct bit duration based on the BAUD macro in inc.h
    localparam bit_duration = 1000000000 / 9600;
 
    U_TOP #(
        .SYS_CLK_FREQ(50000000),
        .BAUD_RATE(9600)
    ) utx (    
        .sys_clk(sys_clk1),
        .sys_rst_l(sys_rst_l),
        .xmitH(xmit_H),
        .xmit_dataH(xmit_dataH),
        .uart_XMIT_dataH(uart_XMIT_dataH),
        .xmit_active(xmit_active),
        .xmit_doneH(xmit_doneH),
        .rec_readyH(rec_ready1),
        .rec_busy(rec_busy1),
        .rec_dataH(rec_dataH1),
        .uart_REC_dataH(uart_XMIT_dataH) // Loopback
    );
 
    U_TOP #(
        .SYS_CLK_FREQ(50000000),
        .BAUD_RATE(9600)
    ) urx (
        .sys_clk(sys_clk2),
        .sys_rst_l(sys_rst_l),
        .uart_REC_dataH(uart_XMIT_dataH),
        .rec_readyH(rec_ready2),
        .rec_busy(rec_busy2),
        .rec_dataH(rec_dataH2),
        .xmitH(xmit_H),
        .xmit_dataH(xmit_dataH)
    );
 
    U_TOP #(
        .SYS_CLK_FREQ(50000000),
        .BAUD_RATE(9600)
    ) urx_slow (
        .sys_clk(sys_clk3),
        .sys_rst_l(sys_rst_l),
        .uart_REC_dataH(uart_XMIT_dataH),
        .rec_readyH(rec_ready3),
        .rec_busy(rec_busy3),
        .rec_dataH(rec_dataH3),
        .xmitH(xmit_H),
        .xmit_dataH(xmit_dataH)
    );
 
    task sys_reset;
        begin
            sys_rst_l = 0;
            #100;
            sys_rst_l = 1;
        end
    endtask
 
    task send_byte;
        input reg [7:0] data;
        begin
            wait(xmit_doneH);
            xmit_dataH = data;
            xmit_H = 1;
            // Wait until transmitter acknowledges and enters S_START before dropping xmit_H
            wait(xmit_active); 
            xmit_H = 0;
            // Wait for full physical serial transmission to finish
            wait(xmit_doneH);
            #(2 * bit_duration); // Stabilization buffer
        end
    endtask
 
    task send_byte_later_reset;
        input reg [7:0] data;
        input integer delay;
        begin
            wait(xmit_doneH);
            xmit_dataH = data;
            xmit_H = 1;
            wait(xmit_active);
            xmit_H = 0;
            #(delay);
            sys_reset();
        end
    endtask
 
    task send_continuous_bytes;
        input integer num_bytes;
        integer i;
        reg [7:0] data;
        begin
            for(i = 0; i < num_bytes; i = i + 1) begin
                data = $urandom;
                wait(xmit_doneH);
                xmit_dataH = data;
                xmit_H = 1;
                wait(xmit_active);
                xmit_H = 0;
                
                wait(xmit_doneH);
                #(2 * bit_duration);
                check_received_byte(data, 1'b0); 
            end
        end
    endtask
 
    task pseudo_start_bit;
        begin
            wait(xmit_doneH);
            // Use force/release since line is driven actively by the utx output port
            force uart_XMIT_dataH = 0;
            fork
                wait(rec_busy1);
                wait(rec_busy2);
                wait(rec_busy3);
            join
            #50;
            release uart_XMIT_dataH;
            #(2 * bit_duration);
        end
    endtask
 
    task invalid_states;
        begin
           // Reference the correct sub-instances (tx, rx) and correct variable names (state)
           force utx.tx.state = 3'b111;
           force utx.rx.state = 3'b111;
           force urx.tx.state = 3'b111;
           force urx.rx.state = 3'b111;
           force urx_slow.tx.state = 3'b111;
           force urx_slow.rx.state = 3'b111;
           #(2 * bit_duration);
           
           release utx.tx.state;
           release utx.rx.state;
           release urx.tx.state;
           release urx.rx.state;
           release urx_slow.tx.state;
           release urx_slow.rx.state;
           
           #(2 * bit_duration);
        end
    endtask
 
    task negative_test;
        begin
            send_byte(8'hFF);
            check_received_byte(8'h00, 1'b1); // Mismatch expected flag is active
        end
    endtask
 
    task check_received_byte;
        input reg [7:0] expected_data;
        input reg err_expected; 
        fork
            begin
                wait(rec_ready1);
                #1;
                if(rec_dataH1 !== expected_data) begin
                    $display("Time: %0t, %s: Expected %h, received %h on utx", $time, (!err_expected ? "ERROR (REAL)" : "SUCCESS (Intentional Error)"), expected_data, rec_dataH1);
                end else begin
                    $display("Time: %0t, SUCCESS: Received expected data %h on utx", $time, rec_dataH1);
                end
            end
            begin
                wait(rec_ready2);
                #1;
                if(rec_dataH2 !== expected_data) begin
                    $display("Time: %0t, %s: Expected %h, received %h on urx", $time, (!err_expected ? "ERROR (REAL)" : "SUCCESS (Intentional Error)"), expected_data, rec_dataH2);
                end else begin
                    $display("Time: %0t, SUCCESS: Received expected data %h on urx", $time, rec_dataH2);
                end
            end
            begin
                wait(rec_ready3);
                #1;
                if(rec_dataH3 !== expected_data) begin
                    $display("Time: %0t, %s: Expected %h, received %h on urx_slow", $time, (!err_expected ? "ERROR (REAL)" : "SUCCESS (Intentional Error)"), expected_data, rec_dataH3);
                end else begin
                    $display("Time: %0t, SUCCESS: Received expected data %h on urx_slow", $time, rec_dataH3);
                end
            end
        join
    endtask
 
    task drivmonscore;
        integer i;
        reg [7:0] test_data;
        begin
            for(i = 1; i <= 5; i = i + 1) begin
                test_data = $urandom;
                send_byte(test_data); 
                check_received_byte(test_data, 1'b0); 
            end
            send_byte_later_reset(8'hA5, bit_duration * 5);
            send_byte_later_reset(8'h3C, bit_duration / 3);
            check_received_byte(8'h00, 1'b0);
            send_continuous_bytes(10);
            pseudo_start_bit();
            invalid_states();
            negative_test();
        end
    endtask
 
    initial begin
        sys_reset();
        drivmonscore();
        $finish;
    end
 
endmodule
