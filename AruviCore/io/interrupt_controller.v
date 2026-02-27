/**
 * Interrupt Controller
 * 
 * Manages interrupt requests for the 32-bit microprocessor.
 * Essential for handling multiple interrupt sources in a Linux system.
 * 
 * Features:
 * - 8 interrupt sources
 * - Priority encoding
 * - Interrupt masking
 * - Edge and level triggering
 * - Interrupt vector generation
 * - 8-bit I/O interface for register access
 */

module interrupt_controller (
    input wire clk,
    input wire rst_n,
    
    // CPU interface
    input wire [2:0] addr,
    input wire [7:0] data_in,
    output reg [7:0] data_out,
    input wire read,
    input wire write,
    input wire cs,
    
    // Interrupt sources
    input wire [7:0] irq_in,
    
    // CPU interrupt interface
    output wire [7:0] irq_out,
    output wire [2:0] irq_vector,
    input wire irq_ack
);

    // Register addresses
    localparam INT_STATUS   = 3'b000; // Interrupt status (read-only)
    localparam INT_MASK     = 3'b001; // Interrupt mask register
    localparam INT_TRIGGER  = 3'b010; // Trigger type (0=level, 1=edge)
    localparam INT_PENDING  = 3'b011; // Pending interrupts (read-only)
    localparam INT_PRIORITY = 3'b100; // Priority configuration
    localparam INT_VECTOR   = 3'b101; // Vector register (read-only)
    localparam INT_ACK      = 3'b110; // Acknowledge register (write-only)
    
    // Registers
    reg [7:0] mask_reg;
    reg [7:0] trigger_reg;
    reg [7:0] priority_reg;
    
    // Internal signals
    reg [7:0] irq_sync;
    reg [7:0] irq_prev;
    reg [7:0] edge_detect;
    reg [7:0] pending_reg;
    wire [7:0] active_irqs;
    
    // Interrupt priority encoder
    reg [2:0] highest_priority;
    reg interrupt_active;
    
    // Synchronize interrupt inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_sync <= 8'h00;
            irq_prev <= 8'h00;
        end else begin
            irq_sync <= irq_in;
            irq_prev <= irq_sync;
        end
    end
    
    // Edge detection
    always @(*) begin
        edge_detect = irq_sync & ~irq_prev; // Rising edge
    end
    
    // Pending interrupt register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_reg <= 8'h00;
        end else begin
            // Set pending interrupts
            pending_reg <= pending_reg | 
                          ((trigger_reg & edge_detect) |     // Edge triggered
                           (~trigger_reg & irq_sync));       // Level triggered
            
            // Clear acknowledged interrupts
            if (cs && write && (addr == INT_ACK)) begin
                pending_reg <= pending_reg & ~data_in;
            end else if (irq_ack && interrupt_active) begin
                pending_reg[highest_priority] <= 1'b0;
            end
        end
    end
    
    // Active interrupts (pending and not masked)
    assign active_irqs = pending_reg & ~mask_reg;
    
    // Priority encoder - find highest priority active interrupt
    always @(*) begin
        interrupt_active = 1'b0;
        highest_priority = 3'b000;
        
        // Priority order: 0 (highest) to 7 (lowest)
        if (active_irqs[0]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b000;
        end else if (active_irqs[1]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b001;
        end else if (active_irqs[2]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b010;
        end else if (active_irqs[3]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b011;
        end else if (active_irqs[4]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b100;
        end else if (active_irqs[5]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b101;
        end else if (active_irqs[6]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b110;
        end else if (active_irqs[7]) begin
            interrupt_active = 1'b1;
            highest_priority = 3'b111;
        end
    end
    
    // Output interrupt request
    assign irq_out = active_irqs;
    assign irq_vector = highest_priority;
    
    // CPU interface
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask_reg <= 8'hFF;     // All interrupts masked by default
            trigger_reg <= 8'h00;  // All level triggered by default
            priority_reg <= 8'h00; // Default priority
        end else if (cs && write) begin
            case (addr)
                INT_MASK: begin
                    mask_reg <= data_in;
                end
                
                INT_TRIGGER: begin
                    trigger_reg <= data_in;
                end
                
                INT_PRIORITY: begin
                    priority_reg <= data_in;
                end
                
                INT_ACK: begin
                    // Handled in pending register logic
                end
            endcase
        end
    end
    
    // CPU read data mux
    always @(*) begin
        case (addr)
            INT_STATUS: data_out = irq_sync;
            INT_MASK: data_out = mask_reg;
            INT_TRIGGER: data_out = trigger_reg;
            INT_PENDING: data_out = pending_reg;
            INT_PRIORITY: data_out = priority_reg;
            INT_VECTOR: data_out = {5'b00000, highest_priority};
            default: data_out = 8'h00;
        endcase
    end
    
endmodule
