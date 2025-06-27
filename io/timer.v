/**
 * System Timer
 * 
 * Provides timing services for the 8-bit microprocessor.
 * Essential for task scheduling in a Linux system.
 * 
 * Features:
 * - 16-bit timer counter
 * - Configurable prescaler
 * - Compare match interrupts
 * - Periodic and one-shot modes
 * - System tick generation
 */

module timer (
    input wire clk,
    input wire rst_n,
    
    // CPU interface
    input wire [2:0] addr,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    input wire read,
    input wire write,
    input wire cs,
    
    // Interrupt output
    output wire interrupt
);

    // Register addresses
    localparam TIMER_CTRL     = 3'b000; // Control register
    localparam TIMER_STATUS   = 3'b001; // Status register
    localparam TIMER_COUNT_L  = 3'b010; // Counter low byte
    localparam TIMER_COUNT_H  = 3'b011; // Counter high byte
    localparam TIMER_COMP_L   = 3'b100; // Compare low byte
    localparam TIMER_COMP_H   = 3'b101; // Compare high byte
    localparam TIMER_PRESCALE = 3'b110; // Prescaler register
    
    // Control register bits
    localparam CTRL_ENABLE    = 0;
    localparam CTRL_MODE      = 1; // 0=one-shot, 1=continuous
    localparam CTRL_INT_EN    = 2;
    localparam CTRL_RESET     = 3;
    
    // Status register bits
    localparam STATUS_MATCH   = 0;
    localparam STATUS_RUNNING = 1;
    
    // Registers
    reg [7:0] ctrl_reg;
    reg [7:0] status_reg;
    reg [15:0] counter;
    reg [15:0] compare_value;
    reg [7:0] prescaler_reg;
    
    // Internal signals
    reg [7:0] prescaler_count;
    wire prescaler_tick;
    wire counter_enable;
    wire compare_match;
    reg match_detected;
    
    // Prescaler logic
    assign prescaler_tick = (prescaler_count == prescaler_reg);
    assign counter_enable = ctrl_reg[CTRL_ENABLE] && prescaler_tick;
    
    // Compare match detection
    assign compare_match = (counter == compare_value);
    
    // Interrupt generation
    assign interrupt = ctrl_reg[CTRL_INT_EN] && status_reg[STATUS_MATCH];
    
    // Main timer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 8'h00;
            status_reg <= 8'h00;
            counter <= 16'h0000;
            compare_value <= 16'hFFFF;
            prescaler_reg <= 8'h00;
            prescaler_count <= 8'h00;
            match_detected <= 1'b0;
        end else begin
            // Prescaler
            if (ctrl_reg[CTRL_ENABLE]) begin
                if (prescaler_tick) begin
                    prescaler_count <= 8'h00;
                end else begin
                    prescaler_count <= prescaler_count + 1;
                end
            end
            
            // Main counter
            if (ctrl_reg[CTRL_RESET]) begin
                counter <= 16'h0000;
                status_reg[STATUS_MATCH] <= 1'b0;
                match_detected <= 1'b0;
            end else if (counter_enable) begin
                if (compare_match && !match_detected) begin
                    // Compare match detected
                    status_reg[STATUS_MATCH] <= 1'b1;
                    match_detected <= 1'b1;
                    
                    if (ctrl_reg[CTRL_MODE]) begin
                        // Continuous mode - reset counter
                        counter <= 16'h0000;
                        match_detected <= 1'b0;
                    end else begin
                        // One-shot mode - stop timer
                        ctrl_reg[CTRL_ENABLE] <= 1'b0;
                    end
                end else if (!compare_match) begin
                    counter <= counter + 1;
                    match_detected <= 1'b0;
                end
            end
            
            // Status register updates
            status_reg[STATUS_RUNNING] <= ctrl_reg[CTRL_ENABLE];
            
            // CPU writes
            if (cs && write) begin
                case (addr)
                    TIMER_CTRL: begin
                        ctrl_reg <= data_in;
                    end
                    
                    TIMER_STATUS: begin
                        // Writing 1 to STATUS_MATCH clears it
                        if (data_in[STATUS_MATCH]) begin
                            status_reg[STATUS_MATCH] <= 1'b0;
                        end
                    end
                    
                    TIMER_COUNT_L: begin
                        counter[7:0] <= data_in;
                    end
                    
                    TIMER_COUNT_H: begin
                        counter[15:8] <= data_in;
                    end
                    
                    TIMER_COMP_L: begin
                        compare_value[7:0] <= data_in;
                    end
                    
                    TIMER_COMP_H: begin
                        compare_value[15:8] <= data_in;
                    end
                    
                    TIMER_PRESCALE: begin
                        prescaler_reg <= data_in;
                    end
                endcase
            end
        end
    end
    
    // CPU read data mux
    always @(*) begin
        case (addr)
            TIMER_CTRL: data_out = ctrl_reg;
            TIMER_STATUS: data_out = status_reg;
            TIMER_COUNT_L: data_out = counter[7:0];
            TIMER_COUNT_H: data_out = counter[15:8];
            TIMER_COMP_L: data_out = compare_value[7:0];
            TIMER_COMP_H: data_out = compare_value[15:8];
            TIMER_PRESCALE: data_out = prescaler_reg;
            default: data_out = 8'h00;
        endcase
    end
    
endmodule
