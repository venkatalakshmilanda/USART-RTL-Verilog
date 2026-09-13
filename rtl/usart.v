`timescale 1ns/1ps

module usart #(
    parameter integer CLK_FREQ  = 1_000_000,
    parameter integer BAUD_RATE = 9_600
)(
    input  wire       clk,
    input  wire       reset,

    // TX interface
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output reg        tx,
    output reg        tx_busy,

    // RX interface
    input  wire       rx,8-bit asynchronous USART RTL design in Verilog with baud-rate generation, FSM-based TX/RX, frame synchronization, and loopback verification.
);

    localparam integer BAUD_TICKS = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BAUD  = BAUD_TICKS / 2;

    // RX synchronizer
    reg rx_sync1;
    reg rx_sync2;

    always @(posedge clk) begin
        if (reset) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end
        else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    // TX states
    localparam TX_IDLE  = 2'd0;
    localparam TX_START = 2'd1;
    localparam TX_DATA  = 2'd2;
    localparam TX_STOP  = 2'd3;

    reg [1:0] tx_state;
    reg [7:0] tx_shift_reg;
    reg [3:0] tx_bit_count;
    integer tx_baud_count;

    // TX logic
    always @(posedge clk) begin
        if (reset) begin
            tx_state      <= TX_IDLE;
            tx            <= 1'b1;
            tx_busy       <= 1'b0;
            tx_shift_reg  <= 8'b0;
            tx_bit_count  <= 4'd0;
            tx_baud_count <= 0;
        end
        else begin
            case (tx_state)

                TX_IDLE: begin
                    tx            <= 1'b1;
                    tx_busy       <= 1'b0;
                    tx_baud_count <= 0;
                    tx_bit_count  <= 0;

                    if (tx_start) begin
                        tx_shift_reg  <= tx_data;
                        tx            <= 1'b0;
                        tx_busy       <= 1'b1;
                        tx_baud_count <= 0;
                        tx_state      <= TX_START;
                    end
                end

                TX_START: begin
                    tx <= 1'b0;

                    if (tx_baud_count == BAUD_TICKS - 1) begin
                        tx_baud_count <= 0;
                        tx_bit_count  <= 0;
                        tx            <= tx_shift_reg[0];
                        tx_state      <= TX_DATA;
                    end
                    else begin
                        tx_baud_count <= tx_baud_count + 1;
                    end
                end

                TX_DATA: begin
                    tx <= tx_shift_reg[0];

                    if (tx_baud_count == BAUD_TICKS - 1) begin
                        tx_baud_count <= 0;

                        if (tx_bit_count == 7) begin
                            tx       <= 1'b1;
                            tx_state <= TX_STOP;
                        end
                        else begin
                            tx_bit_count <= tx_bit_count + 1;
                            tx_shift_reg <= tx_shift_reg >> 1;
                            tx           <= tx_shift_reg[1];
                        end
                    end
                    else begin
                        tx_baud_count <= tx_baud_count + 1;
                    end
                end

                TX_STOP: begin
                    tx <= 1'b1;

                    if (tx_baud_count == BAUD_TICKS - 1) begin
                        tx_baud_count <= 0;
                        tx_busy       <= 1'b0;
                        tx_state      <= TX_IDLE;
                    end
                    else begin
                        tx_baud_count <= tx_baud_count + 1;
                    end
                end

                default: begin
                    tx_state <= TX_IDLE;
                    tx       <= 1'b1;
                    tx_busy  <= 1'b0;
                end

            endcase
        end
    end

    // RX states
    localparam RX_IDLE  = 2'd0;
    localparam RX_START = 2'd1;
    localparam RX_DATA  = 2'd2;
    localparam RX_STOP  = 2'd3;

    reg [1:0] rx_state;
    reg [7:0] rx_shift_reg;
    reg [3:0] rx_bit_count;
    integer rx_baud_count;

    // RX logic
    always @(posedge clk) begin
        if (reset) begin
            rx_state      <= RX_IDLE;
            rx_shift_reg  <= 8'b0;
            rx_bit_count  <= 4'd0;
            rx_baud_count <= 0;
            rx_data       <= 8'b0;
            rx_valid      <= 1'b0;
            rx_error      <= 1'b0;
        end
        else begin
            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (rx_state)

                RX_IDLE: begin
                    rx_baud_count <= 0;
                    rx_bit_count  <= 0;

                    if (rx_sync2 == 1'b0) begin
                        rx_baud_count <= 0;
                        rx_state      <= RX_START;
                    end
                end

                RX_START: begin
                    if (rx_baud_count == HALF_BAUD - 1) begin
                        rx_baud_count <= 0;

                        if (rx_sync2 == 1'b0) begin
                            rx_bit_count <= 0;
                            rx_state     <= RX_DATA;
                        end
                        else begin
                            rx_state <= RX_IDLE;
                        end
                    end
                    else begin
                        rx_baud_count <= rx_baud_count + 1;
                    end
                end

                RX_DATA: begin
                    if (rx_baud_count == BAUD_TICKS - 1) begin
                        rx_baud_count <= 0;
                        rx_shift_reg[rx_bit_count] <= rx_sync2;

                        if (rx_bit_count == 7) begin
                            rx_bit_count <= 0;
                            rx_state     <= RX_STOP;
                        end
                        else begin
                            rx_bit_count <= rx_bit_count + 1;
                        end
                    end
                    else begin
                        rx_baud_count <= rx_baud_count + 1;
                    end
                end

                RX_STOP: begin
                    if (rx_baud_count == BAUD_TICKS - 1) begin
                        rx_baud_count <= 0;

                        if (rx_sync2 == 1'b1) begin
                            rx_data  <= rx_shift_reg;
                            rx_valid <= 1'b1;
                        end
                        else begin
                            rx_error <= 1'b1;
                        end

                        rx_state <= RX_IDLE;
                    end
                    else begin
                        rx_baud_count <= rx_baud_count + 1;
                    end
                end

                default: begin
                    rx_state <= RX_IDLE;
                end

            endcase
        end
    end

endmodule

