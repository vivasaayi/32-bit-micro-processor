/**
 * UART (Universal Asynchronous Receiver Transmitter)
 * 
 * Serial communication interface for the 32-bit microprocessor.
 * Essential for console I/O in a Linux system.
 * 
 * Features:
 * - 8-bit data, 1 start bit, 1 stop bit
 * - Configurable baud rate
 * - TX/RX FIFOs
 * - Interrupt generation
 * - Status flags
 * - 8-bit I/O interface for register access
 */

module uart (
    input wire clk,
    input wire rst_n,
    
    // CPU interface
    input wire [2:0] addr,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    input wire read,
    input wire write,
    input wire cs,
    
    // Serial interface
    input wire rx,
    output wire tx,
    
    // Interrupt
    output wire interrupt,
    
    // Clock divider for baud rate
    input wire [15:0] baud_div
);

    // Register addresses
    localparam UART_DATA   = 3'b000; // Data register
    localparam UART_STATUS = 3'b001; // Status register
    localparam UART_CTRL   = 3'b010; // Control register
    localparam UART_BAUD_L = 3'b011; // Baud rate low
    localparam UART_BAUD_H = 3'b100; // Baud rate high
    
    // Status register bits
    localparam STATUS_TX_READY = 0;
    localparam STATUS_RX_READY = 1;
    localparam STATUS_TX_EMPTY = 2;
    localparam STATUS_RX_FULL  = 3;
    localparam STATUS_FRAME_ERR = 4;
    localparam STATUS_OVERRUN  = 5;
    
    // Control register bits
    localparam CTRL_TX_EN     = 0;
    localparam CTRL_RX_EN     = 1;
    localparam CTRL_TX_INT_EN = 2;
    localparam CTRL_RX_INT_EN = 3;
    
    // Registers
    reg [7:0] status_reg;
    reg [7:0] ctrl_reg;
    reg [15:0] baud_rate_div;
    
    // TX FIFO (4 entries)
    reg [7:0] tx_fifo [0:3];
    reg [1:0] tx_fifo_head, tx_fifo_tail;
    reg [2:0] tx_fifo_count;
    wire tx_fifo_empty, tx_fifo_full;
    
    // RX FIFO (4 entries)
    reg [7:0] rx_fifo [0:3];
    reg [1:0] rx_fifo_head, rx_fifo_tail;
    reg [2:0] rx_fifo_count;
    wire rx_fifo_empty, rx_fifo_full;
    
    // TX state machine
    localparam TX_IDLE = 2'b00;
    localparam TX_START = 2'b01;
    localparam TX_DATA = 2'b10;
    localparam TX_STOP = 2'b11;
    
    reg [1:0] tx_state;
    reg [7:0] tx_data;
    reg [2:0] tx_bit_count;
    reg [15:0] tx_baud_count;
    reg tx_reg;
    
    // RX state machine
    localparam RX_IDLE = 2'b00;
    localparam RX_START = 2'b01;
    localparam RX_DATA = 2'b10;
    localparam RX_STOP = 2'b11;
    
    reg [1:0] rx_state;
    reg [7:0] rx_data;
    reg [2:0] rx_bit_count;
    reg [15:0] rx_baud_count;
    reg rx_sample;
    
    // FIFO status
    assign tx_fifo_empty = (tx_fifo_count == 0);
    assign tx_fifo_full = (tx_fifo_count == 4);
    assign rx_fifo_empty = (rx_fifo_count == 0);
    assign rx_fifo_full = (rx_fifo_count == 4);
    
    // Status register
    always @(*) begin
        status_reg[STATUS_TX_READY] = !tx_fifo_full;
        status_reg[STATUS_RX_READY] = !rx_fifo_empty;
        status_reg[STATUS_TX_EMPTY] = tx_fifo_empty && (tx_state == TX_IDLE);
        status_reg[STATUS_RX_FULL] = rx_fifo_full;
        status_reg[STATUS_FRAME_ERR] = 1'b0; // Not implemented
        status_reg[STATUS_OVERRUN] = 1'b0;   // Not implemented
        status_reg[7:6] = 2'b00;
    end
    
    // Interrupt generation
    assign interrupt = (ctrl_reg[CTRL_TX_INT_EN] && status_reg[STATUS_TX_READY]) ||
                      (ctrl_reg[CTRL_RX_INT_EN] && status_reg[STATUS_RX_READY]);
    
    // CPU interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 8'h03; // TX and RX enabled by default
            baud_rate_div <= 16'd434; // Default to 9600 baud at 50MHz
            tx_fifo_head <= 2'b00;
            tx_fifo_tail <= 2'b00;
            tx_fifo_count <= 3'b000;
            rx_fifo_head <= 2'b00;
            rx_fifo_tail <= 2'b00;
            rx_fifo_count <= 3'b000;
        end else if (cs && write) begin
            case (addr)
                UART_DATA: begin
                    if (!tx_fifo_full) begin
                        tx_fifo[tx_fifo_head] <= data_in;
                        tx_fifo_head <= tx_fifo_head + 1;
                        tx_fifo_count <= tx_fifo_count + 1;
                    end
                end
                
                UART_CTRL: begin
                    ctrl_reg <= data_in;
                end
                
                UART_BAUD_L: begin
                    baud_rate_div[7:0] <= data_in;
                end
                
                UART_BAUD_H: begin
                    baud_rate_div[15:8] <= data_in;
                end
            endcase
        end else if (cs && read) begin
            case (addr)
                UART_DATA: begin
                    if (!rx_fifo_empty) begin
                        rx_fifo_tail <= rx_fifo_tail + 1;
                        rx_fifo_count <= rx_fifo_count - 1;
                    end
                end
            endcase
        end
        
        // RX FIFO write (from RX state machine)
        if (rx_state == RX_STOP && rx_baud_count == 0 && !rx_fifo_full) begin
            rx_fifo[rx_fifo_head] <= rx_data;
            rx_fifo_head <= rx_fifo_head + 1;
            rx_fifo_count <= rx_fifo_count + 1;
        end
        
        // TX FIFO read (from TX state machine)
        if (tx_state == TX_IDLE && !tx_fifo_empty) begin
            tx_fifo_tail <= tx_fifo_tail + 1;
            tx_fifo_count <= tx_fifo_count - 1;
        end
    end
    
    // CPU read data mux
    always @(*) begin
        case (addr)
            UART_DATA: data_out = rx_fifo_empty ? 8'h00 : rx_fifo[rx_fifo_tail];
            UART_STATUS: data_out = status_reg;
            UART_CTRL: data_out = ctrl_reg;
            UART_BAUD_L: data_out = baud_rate_div[7:0];
            UART_BAUD_H: data_out = baud_rate_div[15:8];
            default: data_out = 8'h00;
        endcase
    end
    
    // TX state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= TX_IDLE;
            tx_data <= 8'h00;
            tx_bit_count <= 3'b000;
            tx_baud_count <= 16'h0000;
            tx_reg <= 1'b1; // Idle high
        end else if (ctrl_reg[CTRL_TX_EN]) begin
            case (tx_state)
                TX_IDLE: begin
                    tx_reg <= 1'b1;
                    if (!tx_fifo_empty) begin
                        tx_data <= tx_fifo[tx_fifo_tail];
                        tx_state <= TX_START;
                        tx_baud_count <= baud_rate_div;
                    end
                end
                
                TX_START: begin
                    tx_reg <= 1'b0; // Start bit
                    if (tx_baud_count == 0) begin
                        tx_state <= TX_DATA;
                        tx_bit_count <= 3'b000;
                        tx_baud_count <= baud_rate_div;
                    end else begin
                        tx_baud_count <= tx_baud_count - 1;
                    end
                end
                
                TX_DATA: begin
                    tx_reg <= tx_data[tx_bit_count];
                    if (tx_baud_count == 0) begin
                        if (tx_bit_count == 7) begin
                            tx_state <= TX_STOP;
                        end else begin
                            tx_bit_count <= tx_bit_count + 1;
                        end
                        tx_baud_count <= baud_rate_div;
                    end else begin
                        tx_baud_count <= tx_baud_count - 1;
                    end
                end
                
                TX_STOP: begin
                    tx_reg <= 1'b1; // Stop bit
                    if (tx_baud_count == 0) begin
                        tx_state <= TX_IDLE;
                    end else begin
                        tx_baud_count <= tx_baud_count - 1;
                    end
                end
            endcase
        end
    end
    
    // RX state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= RX_IDLE;
            rx_data <= 8'h00;
            rx_bit_count <= 3'b000;
            rx_baud_count <= 16'h0000;
        end else if (ctrl_reg[CTRL_RX_EN]) begin
            case (rx_state)
                RX_IDLE: begin
                    if (!rx) begin // Start bit detected
                        rx_state <= RX_START;
                        rx_baud_count <= baud_rate_div >> 1; // Sample in middle
                    end
                end
                
                RX_START: begin
                    if (rx_baud_count == 0) begin
                        if (!rx) begin // Valid start bit
                            rx_state <= RX_DATA;
                            rx_bit_count <= 3'b000;
                            rx_baud_count <= baud_rate_div;
                        end else begin
                            rx_state <= RX_IDLE; // False start
                        end
                    end else begin
                        rx_baud_count <= rx_baud_count - 1;
                    end
                end
                
                RX_DATA: begin
                    if (rx_baud_count == 0) begin
                        rx_data[rx_bit_count] <= rx;
                        if (rx_bit_count == 7) begin
                            rx_state <= RX_STOP;
                        end else begin
                            rx_bit_count <= rx_bit_count + 1;
                        end
                        rx_baud_count <= baud_rate_div;
                    end else begin
                        rx_baud_count <= rx_baud_count - 1;
                    end
                end
                
                RX_STOP: begin
                    if (rx_baud_count == 0) begin
                        rx_state <= RX_IDLE;
                    end else begin
                        rx_baud_count <= rx_baud_count - 1;
                    end
                end
            endcase
        end
    end
    
    assign tx = tx_reg;
    
endmodule
