`timescale 1ns/1ps
module usart_tb;

    parameter CLK_FREQ  = 1_000_000;
    parameter BAUD_RATE = 9_600;

    reg clk;
    reg reset;

    reg [7:0] tx_data;
    reg tx_start;

    wire tx;
    wire tx_busy;

    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_error;

    // Instantiate USART
    usart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .rx(tx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );

    // Generate 1 MHz clock
    initial begin
        clk = 1'b0;
        forever #500 clk = ~clk;
    end

    // Generate VCD file
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, usart_tb);
    end

    // Send one byte
    task send_byte;
        input [7:0] data;
        begin
            wait (tx_busy == 1'b0);

            @(posedge clk);
            tx_data  <= data;
            tx_start <= 1'b1;

            @(posedge clk);
            tx_start <= 1'b0;

            wait (rx_valid == 1'b1);

            @(posedge clk);
        end
    endtask

    // Test sequence
    initial begin
        reset    = 1'b1;
        tx_data  = 8'h00;
        tx_start = 1'b0;

        repeat (10) @(posedge clk);

        reset = 1'b0;

        send_byte(8'h41);    // A
        send_byte(8'h42);    // B
        send_byte(8'h55);    // 55
        send_byte(8'hAA);    // AA
        send_byte(8'hFF);    // FF
        send_byte(8'h00);    // 00

        repeat (20) @(posedge clk);

        $display("================================");
        $display("USART TEST COMPLETED");
        $display("================================");

        $finish;
    end

    // Display received data
    always @(posedge clk) begin
        if (rx_valid) begin
            $display(
                "TIME = %0t ns | RX_DATA = %h | ASCII = %c",
                $time,
                rx_data,
                rx_data
            );
        end

        if (rx_error) begin
            $display(
                "TIME = %0t ns | RX ERROR",
                $time
            );
        end
    end

endmodule

