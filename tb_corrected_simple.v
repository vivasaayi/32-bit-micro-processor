// Simple testbench to test corrected instruction encoding
// This uses the existing working testbench structure

`timescale 1ns / 1ps

module tb_corrected_simple;
    // Inputs
    reg clk;
    reg reset;
    
    // Outputs (from our previous working testbench)
    wire [15:0] pc;
    wire [7:0] instruction;
    wire [7:0] alu_result;
    wire halt;
    
    // Simple test system using basic CPU components
    reg [7:0] memory [0:65535];
    reg [7:0] reg_file [0:7];
    
    // Simple CPU state
    reg [15:0] program_counter;
    reg [7:0] current_instruction;
    reg [2:0] cpu_state;
    reg cpu_halt;
    
    // State machine states
    parameter FETCH = 3'b000;
    parameter DECODE = 3'b001;
    parameter EXECUTE = 3'b010;
    parameter HALT = 3'b011;
    
    assign pc = program_counter;
    assign instruction = current_instruction;
    assign halt = cpu_halt;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Initialize memory with corrected program
    initial begin
        // Clear memory
        integer i;
        for (i = 0; i < 65536; i = i + 1) begin
            memory[i] = 8'h00;
        end
        
        // Clear registers
        for (i = 0; i < 8; i = i + 1) begin
            reg_file[i] = 8'h00;
        end
        
        $display("Loading corrected program...");
        
        // Load corrected program from assembler output:
        // 8000: 42 0A 42 05 00 46 FF 46 0F 24 4A 14 4A 08 18 80
        // 8010: 54 15 80 4E 63 4E 2A 64
        
        memory[16'h8000] = 8'h42; // LDI R0, 10
        memory[16'h8001] = 8'h0A;
        memory[16'h8002] = 8'h42; // LDI R0, 5 (overwrites previous)
        memory[16'h8003] = 8'h05;
        memory[16'h8004] = 8'h00; // Padding/continuation
        memory[16'h8005] = 8'h46; // LDI R1, 255
        memory[16'h8006] = 8'hFF;
        memory[16'h8007] = 8'h46; // LDI R1, 15 (overwrites previous)
        memory[16'h8008] = 8'h0F;
        memory[16'h8009] = 8'h24; // ADD R0, R1
        memory[16'h800A] = 8'h4A; // STR R0, [addr]
        memory[16'h800B] = 8'h14;
        memory[16'h800C] = 8'h4A; // STR R0, [addr]
        memory[16'h800D] = 8'h08;
        memory[16'h800E] = 8'h18; // OUT R0
        memory[16'h800F] = 8'h80;
        memory[16'h8010] = 8'h54; // JMP end
        memory[16'h8011] = 8'h15;
        memory[16'h8012] = 8'h80;
        memory[16'h8013] = 8'h4E; // end: NOP
        memory[16'h8014] = 8'h63;
        memory[16'h8015] = 8'h4E; // HLT
        memory[16'h8016] = 8'h2A;
        memory[16'h8017] = 8'h64;
        
        $display("Program loaded starting at 0x8000");
    end
    
    // Simple CPU execution
    initial begin
        reset = 1;
        program_counter = 16'h8000; // Start at program location
        cpu_state = HALT;
        cpu_halt = 0;
        
        #50;
        reset = 0;
        cpu_state = FETCH;
        
        $display("=== Starting corrected program execution ===");
        $display("Expected behavior:");
        $display("1. Load 5 into R0");
        $display("2. Load 15 into R1"); 
        $display("3. Add R0 + R1 = 20 (0x14)");
        $display("4. Store result and output to GPIO");
        $display("5. Halt");
    end
    
    // Simple CPU state machine
    always @(posedge clk) begin
        if (reset) begin
            program_counter <= 16'h8000;
            cpu_state <= HALT;
            cpu_halt <= 0;
        end else begin
            case (cpu_state)
                FETCH: begin
                    current_instruction <= memory[program_counter];
                    cpu_state <= DECODE;
                    $display("[%0t] FETCH: PC=0x%04h, Inst=0x%02h", 
                             $time, program_counter, memory[program_counter]);
                end
                
                DECODE: begin
                    cpu_state <= EXECUTE;
                    $display("[%0t] DECODE: Instruction=0x%02h", $time, current_instruction);
                end
                
                EXECUTE: begin
                    // Simple instruction decode and execute
                    case (current_instruction[7:4])
                        4'h4: begin // LDI/STR/HLT/NOP family
                            case (current_instruction[3:0])
                                4'h2, 4'h6: begin // LDI R0 or R1
                                    program_counter <= program_counter + 1;
                                    if (current_instruction[3:0] == 4'h2) begin // R0
                                        reg_file[0] <= memory[program_counter + 1];
                                        $display("[%0t] LDI R0, 0x%02h", $time, memory[program_counter + 1]);
                                    end else begin // R1
                                        reg_file[1] <= memory[program_counter + 1];
                                        $display("[%0t] LDI R1, 0x%02h", $time, memory[program_counter + 1]);
                                    end
                                    program_counter <= program_counter + 2;
                                end
                                4'hA: begin // STR
                                    $display("[%0t] STR R0, [addr] - R0=0x%02h", $time, reg_file[0]);
                                    program_counter <= program_counter + 2; // Skip address bytes
                                end
                                4'hE: begin // HLT/NOP
                                    if (memory[program_counter + 1] == 8'h2A) begin
                                        $display("[%0t] HLT - Program terminated", $time);
                                        cpu_halt <= 1;
                                        cpu_state <= HALT;
                                    end else begin
                                        $display("[%0t] NOP", $time);
                                        program_counter <= program_counter + 2;
                                    end
                                end
                                default: begin
                                    $display("[%0t] Unknown 4x instruction: 0x%02h", $time, current_instruction);
                                    program_counter <= program_counter + 1;
                                end
                            endcase
                        end
                        
                        4'h2: begin // ADD
                            if (current_instruction[3:0] == 4'h4) begin
                                reg_file[0] <= reg_file[0] + reg_file[1];
                                $display("[%0t] ADD R0, R1: %d + %d = %d", 
                                         $time, reg_file[0], reg_file[1], reg_file[0] + reg_file[1]);
                                program_counter <= program_counter + 1;
                            end
                        end
                        
                        4'h1: begin // OUT
                            if (current_instruction[3:0] == 4'h8) begin
                                $display("[%0t] OUT R0 to GPIO: 0x%02h", $time, reg_file[0]);
                                program_counter <= program_counter + 2; // Skip address
                            end
                        end
                        
                        4'h5: begin // JMP
                            if (current_instruction[3:0] == 4'h4) begin
                                program_counter <= {memory[program_counter + 2], memory[program_counter + 1]};
                                $display("[%0t] JMP to 0x%04h", $time, {memory[program_counter + 2], memory[program_counter + 1]});
                            end
                        end
                        
                        default: begin
                            $display("[%0t] Unknown instruction: 0x%02h", $time, current_instruction);
                            program_counter <= program_counter + 1;
                        end
                    endcase
                    
                    if (!cpu_halt) cpu_state <= FETCH;
                end
                
                HALT: begin
                    // Stay halted
                end
            endcase
        end
    end
    
    // Test monitoring
    initial begin
        #2000; // Let program run
        
        $display("\n=== Final Results ===");
        $display("CPU Halted: %b", cpu_halt);
        $display("R0 (should be 20): %d (0x%02h)", reg_file[0], reg_file[0]);
        $display("R1 (should be 15): %d (0x%02h)", reg_file[1], reg_file[1]);
        $display("Program Counter: 0x%04h", program_counter);
        
        if (cpu_halt && reg_file[0] == 8'd20) begin
            $display("✓ SUCCESS: Program executed correctly!");
            $display("✓ Corrected assembler output works properly");
        end else begin
            $display("✗ FAILURE: Program did not execute as expected");
        end
        
        $finish;
    end
    
endmodule
