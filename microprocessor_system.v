/**
 * 32-Bit Microprocessor System
 * 
 * Top-level module that integrates:
 * - 32-bit CPU core
 * - 32-bit memory controller  
 * - Memory management unit (MMU)
 * - I/O controllers
 * - Interrupt controller
 * 
 * Features:
 * - 4GB address space (32-bit addressing)
 * - 32-bit data path
 * - Harvard architecture support
 * - Memory-mapped I/O
 * - Interrupt handling
 */

module microprocessor_system (
    input wire clk,
    input wire rst_n,
    
    // External memory interface
    output wire [31:0] ext_addr,
    inout wire [31:0] ext_data,
    output wire ext_mem_read,
    output wire ext_mem_write,
    output wire ext_mem_enable,
    input wire ext_mem_ready,
    
    // I/O interface
    output wire [7:0] io_addr,
    inout wire [7:0] io_data,
    output wire io_read,
    output wire io_write,
    
    // Interrupt inputs
    input wire [7:0] external_interrupts,
    
    // Status outputs
    output wire system_halted,
    output wire [31:0] pc_out,
    output wire [7:0] cpu_flags
);

    // Internal buses
    wire [31:0] cpu_addr_bus;
    wire [31:0] cpu_data_bus;
    wire cpu_mem_read, cpu_mem_write;
    wire cpu_mem_ready;
    
    // CPU signals
    wire cpu_halted;
    wire cpu_user_mode;
    wire [7:0] cpu_interrupt_req;
    wire cpu_interrupt_ack;
    
    // Memory controller signals
    wire [31:0] mem_addr;
    wire [31:0] mem_data_in, mem_data_out;
    wire mem_read_req, mem_write_req;
    wire mem_ready;
    wire mem_enable;
    
    // Internal memory (for testing) - 64KB mapped to lower addresses
    reg [31:0] internal_memory [0:16383]; // 64KB / 4 bytes = 16K words
    reg [31:0] mem_data_out_reg;
    reg mem_ready_reg;
    
    // Memory address decoding
    wire accessing_internal_mem = (cpu_addr_bus < 32'h00010000); // First 64KB
    wire accessing_external_mem = (cpu_addr_bus >= 32'h00010000);
    
    // Instantiate CPU core
    cpu_core cpu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr_bus(cpu_addr_bus),
        .data_bus(cpu_data_bus),
        .mem_read(cpu_mem_read),
        .mem_write(cpu_mem_write),
        .mem_ready(cpu_mem_ready),
        .interrupt_req(cpu_interrupt_req),
        .interrupt_ack(cpu_interrupt_ack),
        .io_addr(io_addr),
        .io_data(io_data),
        .io_read(io_read),
        .io_write(io_write),
        .halted(cpu_halted),
        .user_mode(cpu_user_mode)
    );
    
    // Internal memory controller
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready_reg <= 1'b0;
            mem_data_out_reg <= 32'h00000000;
        end else begin
            mem_ready_reg <= 1'b1; // Always ready for internal memory
            
            if (accessing_internal_mem) begin
                if (cpu_mem_write) begin
                    internal_memory[cpu_addr_bus[15:2]] <= cpu_data_bus;
                    $display("DEBUG: Memory write at addr=0x%08x, word_addr=%d, data=0x%08x", 
                            cpu_addr_bus, cpu_addr_bus[15:2], cpu_data_bus);
                end
                // Always output data for reads or instruction fetch
                mem_data_out_reg <= internal_memory[cpu_addr_bus[15:2]];
            end else if (accessing_external_mem) begin
                // Pass through to external memory
                mem_ready_reg <= ext_mem_ready;
                if (cpu_mem_read) begin
                    mem_data_out_reg <= ext_data;
                end
            end
        end
    end
    
    // Memory data bus handling - provide data for both reads and instruction fetch
    assign cpu_data_bus = accessing_internal_mem ? mem_data_out_reg : ext_data;
    
    // External memory interface
    assign ext_addr = cpu_addr_bus;
    assign ext_data = (cpu_mem_write && accessing_external_mem) ? cpu_data_bus : 32'hZZZZZZZZ;
    assign ext_mem_read = cpu_mem_read && accessing_external_mem;
    assign ext_mem_write = cpu_mem_write && accessing_external_mem;
    assign ext_mem_enable = accessing_external_mem;
    
    // Memory ready signal
    assign cpu_mem_ready = accessing_internal_mem ? mem_ready_reg : ext_mem_ready;
    
    // Interrupt handling (simplified)
    assign cpu_interrupt_req = external_interrupts;
    
    // Status outputs
    assign system_halted = cpu_halted;
    assign pc_out = cpu_addr_bus; // Simplified - should be actual PC
    assign cpu_flags = 8'h00; // Placeholder
    
    // Initialize internal memory with program
    integer i;
    initial begin
        // Initialize memory to zero
        for (i = 0; i < 16384; i = i + 1) begin
            internal_memory[i] = 32'h00000000;
        end
        
        // Load a simple test program
        // LOADI R1, #42 (Load immediate 42 into R1)
        // LOADI R2, #10 (Load immediate 10 into R2) 
        // ADD R3, R1, R2 (Add R1 and R2, store in R3)
        // HALT
        internal_memory[0] = 32'h2001002A; // LOADI R1, #42
        internal_memory[1] = 32'h2002000A; // LOADI R2, #10
        internal_memory[2] = 32'h00031102; // ADD R3, R1, R2 (simplified encoding)
        internal_memory[3] = 32'hF0000000; // HALT
    end

endmodule
