/**
 * 32-Bit Memory Controller
 * 
 * Handles memory access for the 32-bit microprocessor.
 * Provides interface between CPU and physical memory/cache.
 * 
 * Features:
 * - 32-bit address space (4GB)
 * - 32-bit data path
 * - Memory mapped I/O
 * - Wait state generation
 * - Address decoding
 * - Cache interface
 */

module memory_controller (
    input wire clk,
    input wire rst_n,
    
    // CPU interface
    input wire [31:0] cpu_addr,
    inout wire [31:0] cpu_data,
    input wire cpu_read,
    input wire cpu_write,
    output wire cpu_ready,
    
    // Memory interface
    output wire [31:0] mem_addr,
    inout wire [31:0] mem_data,
    output wire mem_read,
    output wire mem_write,
    output wire mem_cs,
    input wire mem_ready,
    
    // I/O interface
    output wire [7:0] io_addr,
    inout wire [7:0] io_data,
    output wire io_read,
    output wire io_write,
    output wire io_cs,
    input wire io_ready,
    
    // Cache interface
    output wire cache_enable,
    input wire cache_hit,
    input wire cache_ready
);

    // Memory map definitions for 32-bit address space
    localparam USER_SPACE_START   = 32'h00000000;
    localparam USER_SPACE_END     = 32'h7FFFFFFF;
    localparam KERNEL_SPACE_START = 32'h80000000;
    localparam KERNEL_SPACE_END   = 32'hEFFFFFFF;
    localparam IO_SPACE_START     = 32'hF0000000;
    localparam IO_SPACE_END       = 32'hF00FFFFF;
    localparam ROM_SPACE_START    = 32'hF1000000;
    localparam ROM_SPACE_END      = 32'hFFFFFFFF;
    
    // Internal signals
    reg [31:0] data_out;
    wire [31:0] data_in;
    reg is_io_access;
    reg is_mem_access;
    reg access_ready;
    
    // State machine for memory access
    localparam IDLE = 2'b00;
    localparam ACCESS = 2'b01;
    localparam WAIT = 2'b10;
    localparam DONE = 2'b11;
    
    reg [1:0] state, next_state;
    reg [2:0] wait_counter;
    
    // Address decoding
    always @(*) begin
        is_io_access = (cpu_addr >= IO_SPACE_START && cpu_addr <= IO_SPACE_END);
        is_mem_access = !is_io_access;
    end
    
    // Memory/IO chip select generation
    assign mem_cs = is_mem_access && (cpu_read || cpu_write);
    assign io_cs = is_io_access && (cpu_read || cpu_write);
    
    // Address routing
    assign mem_addr = cpu_addr;
    assign io_addr = cpu_addr[7:0]; // Only lower 8 bits for I/O
    
    // Control signal routing
    assign mem_read = is_mem_access && cpu_read;
    assign mem_write = is_mem_access && cpu_write;
    assign io_read = is_io_access && cpu_read;
    assign io_write = is_io_access && cpu_write;
    
    // Cache enable for cacheable regions
    assign cache_enable = (cpu_addr >= USER_SPACE_START && cpu_addr <= KERNEL_SPACE_END);
    
    // Data bus handling
    assign cpu_data = (cpu_read && access_ready) ? data_in : 32'bZ;
    assign mem_data = (mem_write) ? cpu_data : 32'bZ;
    assign io_data = (io_write) ? cpu_data[7:0] : 8'bZ;  // Only lower 8 bits for I/O
    
    // Data input selection
    assign data_in = is_io_access ? {24'h000000, io_data} : mem_data;
    
    // Ready signal generation
    assign cpu_ready = access_ready;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            wait_counter <= 3'b000;
        end else begin
            state <= next_state;
            if (state == WAIT) begin
                wait_counter <= wait_counter + 1;
            end else begin
                wait_counter <= 3'b000;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        access_ready = 1'b0;
        
        case (state)
            IDLE: begin
                if (cpu_read || cpu_write) begin
                    if (cache_enable && cache_hit) begin
                        // Cache hit - immediate access
                        next_state = DONE;
                    end else begin
                        next_state = ACCESS;
                    end
                end
            end
            
            ACCESS: begin
                if (is_io_access) begin
                    if (io_ready) begin
                        next_state = DONE;
                    end else begin
                        next_state = WAIT;
                    end
                end else begin
                    if (mem_ready) begin
                        next_state = DONE;
                    end else begin
                        next_state = WAIT;
                    end
                end
            end
            
            WAIT: begin
                // Wait for memory or I/O to be ready
                if (is_io_access && io_ready) begin
                    next_state = DONE;
                end else if (is_mem_access && mem_ready) begin
                    next_state = DONE;
                end else if (wait_counter >= 3'b111) begin
                    // Timeout - force completion
                    next_state = DONE;
                end
            end
            
            DONE: begin
                access_ready = 1'b1;
                next_state = IDLE;
            end
        endcase
    end
    
endmodule
