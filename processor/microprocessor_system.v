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
    
    // Debug outputs for testing
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instruction,
    output wire [31:0] debug_reg_data,
    output wire [4:0] debug_reg_addr,
    output wire [31:0] debug_result,
    output wire debug_halted
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
    wire [2:0] mem_op_width;
    
    // Memory controller signals
    wire [31:0] mem_addr;
    wire [31:0] mem_data_in, mem_data_out;
    wire mem_read_req, mem_write_req;
    wire mem_ready;
    wire mem_enable;
    
    // Internal memory (for testing) - 1MB mapped to lower addresses
    reg [31:0] internal_memory [0:262143]; // 1MB / 4 bytes = 256K words
    reg [31:0] mem_data_out_reg;
    reg mem_ready_reg;
    
    // Status memory location for test results
    reg [31:0] status_register;
    
    // Memory address decoding
    wire accessing_internal_mem = (cpu_addr_bus < 32'h00100000); // First 1MB
    wire accessing_external_mem = (cpu_addr_bus >= 32'h00100000);
    wire accessing_status_reg = (cpu_addr_bus == 32'h00002000); // Status at 0x2000

    // Store Logic for Byte/Halfword
    wire [1:0] byte_offset = cpu_addr_bus[1:0];
    reg [31:0] write_mask;
    reg [31:0] shifted_data;

    always @(*) begin
        shifted_data = cpu_data_bus;
        write_mask = 32'hFFFFFFFF;

        case (mem_op_width)
            3'b000: begin // SB
                shifted_data = {4{cpu_data_bus[7:0]}};
                case (byte_offset)
                    2'b00: write_mask = 32'h000000FF;
                    2'b01: write_mask = 32'h0000FF00;
                    2'b10: write_mask = 32'h00FF0000;
                    2'b11: write_mask = 32'hFF000000;
                endcase
            end
            3'b001: begin // SH
                shifted_data = {2{cpu_data_bus[15:0]}};
                case (byte_offset[1])
                    1'b0: write_mask = 32'h0000FFFF;
                    1'b1: write_mask = 32'hFFFF0000;
                endcase
            end
            default: begin // SW
                shifted_data = cpu_data_bus;
                write_mask = 32'hFFFFFFFF;
            end
        endcase
    end
    
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
        .little_endian(1'b1),  // Configure as little-endian
        .halted(cpu_halted),
        .user_mode(cpu_user_mode),
        .mem_op_width(mem_op_width)
    );
    
    // Internal memory controller
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready_reg <= 1'b0;
            mem_data_out_reg <= 32'h00000000;
            status_register <= 32'h00000000;
        end else begin
            mem_ready_reg <= 1'b1; // Always ready for internal memory
            
            if (accessing_status_reg) begin
                if (cpu_mem_write) begin
                    status_register <= cpu_data_bus;
                    $display("DEBUG: Status register write: 0x%08x", cpu_data_bus);
                end
            end else if (accessing_internal_mem) begin
                if (cpu_mem_write) begin
                    internal_memory[cpu_addr_bus[19:2]] <= (internal_memory[cpu_addr_bus[19:2]] & ~write_mask) | (shifted_data & write_mask);
                    $display("DEBUG: Memory write at addr=0x%08x, word_addr=%d, data=0x%08x, mask=0x%08x", 
                            cpu_addr_bus, cpu_addr_bus[19:2], shifted_data & write_mask, write_mask);
                end
                // Debug output for reads (data is provided combinationally)
                if (cpu_mem_read && !cpu_mem_write) begin
                    if (cpu_addr_bus < 32'h00001000) begin
                        $display("DEBUG: Memory data read at addr=0x%08x, word_addr=%d, data=0x%08x", 
                                cpu_addr_bus, cpu_addr_bus[19:2], internal_memory[cpu_addr_bus[19:2]]);
                    end else begin
                        $display("DEBUG: Memory instruction fetch at addr=0x%08x, word_addr=%d, data=0x%08x", 
                                cpu_addr_bus, cpu_addr_bus[19:2], internal_memory[cpu_addr_bus[19:2]]);
                    end
                end
            end else if (accessing_external_mem) begin
                // Pass through to external memory
                mem_ready_reg <= ext_mem_ready;
            end
        end
    end
    
    // Memory data bus handling - provide data combinationally for reads
    assign cpu_data_bus = (cpu_mem_read && accessing_internal_mem) ? internal_memory[cpu_addr_bus[19:2]] :
                         (cpu_mem_read && accessing_status_reg) ? status_register :
                         (cpu_mem_read && accessing_external_mem) ? ext_data : 32'hZZZZZZZZ;
    
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
    
    // Debug outputs
    assign debug_pc = cpu_addr_bus;
    assign debug_instruction = internal_memory[cpu_addr_bus[19:2]];
    assign debug_reg_data = cpu_data_bus;
    assign debug_reg_addr = 5'b00001; // R1 for result
    assign debug_result = status_register; // Output status register value
    assign debug_halted = cpu_halted;
    
    // Initialize internal memory with program
    integer i;
    initial begin
        // Initialize memory to zero
        for (i = 0; i < 262144; i = i + 1) begin
            internal_memory[i] = 32'h00000000;
        end
        
        // Default test program loaded at 0x8000 (word address 0x2000)
        // LOADI R1, #42 (Load immediate 42 into R1)
        // LOADI R2, #10 (Load immediate 10 into R2) 
        // ADD R3, R1, R2 (Add R1 and R2, store in R3)
        // HALT
        internal_memory[32768] = 32'h2001002A; // LOADI R1, #42 at 0x8000
        internal_memory[32769] = 32'h2002000A; // LOADI R2, #10 at 0x8004
        internal_memory[32770] = 32'h00031102; // ADD R3, R1, R2 at 0x8008
        internal_memory[32771] = 32'hF0000000; // HALT at 0x800C
    end

endmodule
