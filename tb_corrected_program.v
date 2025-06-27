// Testbench for 8-bit microprocessor system with corrected program
// Tests the comprehensive test program with proper instruction encoding

`timescale 1ns / 1ps

module tb_corrected_program;
    // System inputs
    reg clk;
    reg reset;
    
    // System outputs
    wire halt;
    wire [7:0] gpio_out;
    wire [7:0] uart_tx_data;
    wire uart_tx_valid;
    
    // Memory interface (for observation)
    wire [15:0] mem_addr;
    wire [7:0] mem_data_out;
    wire mem_read;
    wire mem_write;
    
    // Instantiate the microprocessor system
    microprocessor_system uut (
        .clk(clk),
        .reset(reset),
        .halt(halt),
        .gpio_out(gpio_out),
        .uart_tx_data(uart_tx_data),
        .uart_tx_valid(uart_tx_valid)
    );
    
    // Connect memory interface for observation
    assign mem_addr = uut.mem_addr;
    assign mem_data_out = uut.mem_data_out;
    assign mem_read = uut.mem_read;
    assign mem_write = uut.mem_write;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end
    
    // Test procedure
    initial begin
        // Initialize
        $display("=== Corrected Program Test Starting ===");
        reset = 1;
        
        // Load the corrected program into memory
        // This simulates loading the corrected hex file
        $display("Loading corrected program...");
        
        // Wait a few cycles then release reset
        #50;
        reset = 0;
        $display("Released reset, starting execution at address 0x8000");
        
        // Monitor execution
        $monitor("Time: %0t | PC: %04h | Instruction: %02h | GPIO: %02h | Halt: %b", 
                 $time, uut.cpu.pc, uut.cpu.instruction, gpio_out, halt);
        
        // Let the program run
        #1000;
        
        // Check results
        if (halt) begin
            $display("=== Program completed successfully ===");
            $display("Final GPIO output: 0x%02h", gpio_out);
            $display("Memory at 0x8020 (test location): 0x%02h", uut.memory.mem[16'h8020]);
            $display("Memory at 0x8021 (test location): 0x%02h", uut.memory.mem[16'h8021]);
        end else begin
            $display("=== Program did not complete within time limit ===");
            $display("Current GPIO output: 0x%02h", gpio_out);
        end
        
        $display("=== Test Complete ===");
        $finish;
    end
    
    // Initialize memory with the corrected program
    initial begin
        // Clear memory first
        integer i;
        for (i = 0; i < 65536; i = i + 1) begin
            uut.memory.mem[i] = 8'h00;
        end
        
        // Load corrected program starting at 0x8000
        // From the corrected assembler output:
        // 8000: 42 0A 42 05 00 46 FF 46 0F 24 4A 14 4A 08 18 80
        // 8010: 54 15 80 4E 63 4E 2A 64
        
        // LDI R0, 10 (0x0A)
        uut.memory.mem[16'h8000] = 8'h42;  // LDI opcode with R0
        uut.memory.mem[16'h8001] = 8'h0A;  // Immediate value 10
        
        // LDI R0, 5
        uut.memory.mem[16'h8002] = 8'h42;  // LDI opcode with R0  
        uut.memory.mem[16'h8003] = 8'h05;  // Immediate value 5
        uut.memory.mem[16'h8004] = 8'h00;  // Padding or next instruction part
        
        // LDI R1, 255 (0xFF)
        uut.memory.mem[16'h8005] = 8'h46;  // LDI opcode with R1
        uut.memory.mem[16'h8006] = 8'hFF;  // Immediate value 255
        
        // LDI R1, 15 (0x0F)
        uut.memory.mem[16'h8007] = 8'h46;  // LDI opcode with R1
        uut.memory.mem[16'h8008] = 8'h0F;  // Immediate value 15
        
        // ADD R0, R1
        uut.memory.mem[16'h8009] = 8'h24;  // ADD opcode
        
        // STR R0, address
        uut.memory.mem[16'h800A] = 8'h4A;  // STR opcode with R0
        uut.memory.mem[16'h800B] = 8'h14;  // Address low byte
        
        // STR R0, address  
        uut.memory.mem[16'h800C] = 8'h4A;  // STR opcode with R0
        uut.memory.mem[16'h800D] = 8'h08;  // Address low byte
        
        // OUT R0 (write to GPIO)
        uut.memory.mem[16'h800E] = 8'h18;  // OUT opcode
        uut.memory.mem[16'h800F] = 8'h80;  // GPIO address
        
        // JMP end
        uut.memory.mem[16'h8010] = 8'h54;  // JMP opcode
        uut.memory.mem[16'h8011] = 8'h15;  // Jump target low
        uut.memory.mem[16'h8012] = 8'h80;  // Jump target high
        
        // end: NOP
        uut.memory.mem[16'h8013] = 8'h4E;  // NOP opcode
        uut.memory.mem[16'h8014] = 8'h63;  // Additional data
        
        // HLT
        uut.memory.mem[16'h8015] = 8'h4E;  // HLT opcode  
        uut.memory.mem[16'h8016] = 8'h2A;  // HLT parameter
        uut.memory.mem[16'h8017] = 8'h64;  // End marker
        
        $display("Corrected program loaded into memory");
        $display("Program starts at address 0x8000");
        $display("Expected: Load values, add them, store result, output to GPIO, halt");
    end
    
    // Monitor key signals during execution
    always @(posedge clk) begin
        if (!reset && uut.cpu.cpu_en) begin
            $display("[%0t] PC=0x%04h, Inst=0x%02h, R0=0x%02h, R1=0x%02h, ALU=0x%02h", 
                     $time, uut.cpu.pc, uut.cpu.instruction, 
                     uut.cpu.reg_file.registers[0], uut.cpu.reg_file.registers[1],
                     uut.cpu.alu_result);
        end
    end
    
endmodule
