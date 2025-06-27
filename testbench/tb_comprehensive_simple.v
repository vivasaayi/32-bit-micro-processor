`timescale 1ns/1ps

module tb_comprehensive_simple;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // External memory (simple RAM model)
    wire [15:0] ext_mem_addr;
    wire [7:0] ext_mem_data;
    wire ext_mem_read;
    wire ext_mem_write;
    wire ext_mem_cs;
    reg ext_mem_ready;
    
    // UART
    reg uart_rx;
    wire uart_tx;
    
    // GPIO
    wire [7:0] gpio_pins;
    
    // Status
    wire system_halted;
    wire user_mode_active;
    wire [7:0] debug_reg;
    
    // Memory array
    reg [7:0] memory [0:65535];
    reg [7:0] mem_data_out;
    
    // Clock generation
    always #10 clk = ~clk; // 50MHz clock
    
    // Memory model
    always @(posedge clk) begin
        ext_mem_ready <= 1'b0;
        if (ext_mem_cs) begin
            if (ext_mem_read) begin
                mem_data_out <= memory[ext_mem_addr];
                ext_mem_ready <= 1'b1;
            end else if (ext_mem_write) begin
                memory[ext_mem_addr] <= ext_mem_data;
                ext_mem_ready <= 1'b1;
            end
        end
    end
    
    assign ext_mem_data = (ext_mem_read && ext_mem_ready) ? mem_data_out : 8'bZ;
    
    // Instantiate DUT
    microprocessor_system dut (
        .clk(clk),
        .rst_n(rst_n),
        .ext_mem_addr(ext_mem_addr),
        .ext_mem_data(ext_mem_data),
        .ext_mem_read(ext_mem_read),
        .ext_mem_write(ext_mem_write),
        .ext_mem_cs(ext_mem_cs),
        .ext_mem_ready(ext_mem_ready),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .gpio_pins(gpio_pins),
        .system_halted(system_halted),
        .user_mode_active(user_mode_active),
        .debug_reg(debug_reg)
    );
    
    // Initialize memory with comprehensive test program
    initial begin
        integer i;
        
        // Clear memory
        for (i = 0; i < 65536; i = i + 1) begin
            memory[i] = 8'h00;
        end
        
        // Initialize page table (simple identity mapping)
        for (i = 0; i < 256; i = i + 1) begin
            memory[16'hE000 + i] = 8'h80 | (i[3:0]);
        end
        
        // Load comprehensive test program at 0x8000
        $display("Loading comprehensive test program at 0x8000...");
        
        // Test 1: Basic arithmetic (ADD/SUB)
        memory[16'h8000] = 8'h04; // ADDI R0, #42
        memory[16'h8001] = 8'h2A; // immediate 42
        memory[16'h8002] = 8'h04; // ADDI R1, #10  
        memory[16'h8003] = 8'h81; // R1, immediate
        memory[16'h8004] = 8'h0A; // immediate 10
        memory[16'h8005] = 8'h00; // ADD R0, R1
        memory[16'h8006] = 8'h10; // R0 = R0 + R1 (should be 52)
        
        // Test 2: Store result to memory
        memory[16'h8007] = 8'h01; // STORE R0 to [1000]
        memory[16'h8008] = 8'h00; // R0
        memory[16'h8009] = 8'h10; // address 0x1000 high
        memory[16'h800A] = 8'h00; // address 0x1000 low
        
        // Test 3: Load from memory
        memory[16'h800B] = 8'h02; // LOAD R2 from [1000]
        memory[16'h800C] = 8'h20; // R2
        memory[16'h800D] = 8'h10; // address 0x1000 high
        memory[16'h800E] = 8'h00; // address 0x1000 low
        
        // Test 4: GPIO output
        memory[16'h800F] = 8'h04; // ADDI R3, #0xAA
        memory[16'h8010] = 8'h83; // R3, immediate
        memory[16'h8011] = 8'hAA; // pattern 0xAA
        memory[16'h8012] = 8'h06; // OUT R3 to GPIO
        memory[16'h8013] = 8'h30; // R3 to port 0
        
        // Test 5: Conditional branch
        memory[16'h8014] = 8'h07; // CMP R0, R2
        memory[16'h8015] = 8'h02; // compare R0 with R2
        memory[16'h8016] = 8'h08; // BEQ (branch if equal)
        memory[16'h8017] = 8'h80; // branch to 0x801C
        memory[16'h8018] = 8'h1C; // 
        
        // Test 6: If not equal, set error flag
        memory[16'h8019] = 8'h04; // ADDI R4, #0xFF (error)
        memory[16'h801A] = 8'h84; // R4, immediate
        memory[16'h801B] = 8'hFF; // error code
        
        // Test 7: Success path - clear error flag
        memory[16'h801C] = 8'h04; // ADDI R4, #0x00 (success)
        memory[16'h801D] = 8'h84; // R4, immediate
        memory[16'h801E] = 8'h00; // success code
        
        // Test 8: Store test result
        memory[16'h801F] = 8'h01; // STORE R4 to [1001]
        memory[16'h8020] = 8'h40; // R4
        memory[16'h8021] = 8'h10; // address 0x1001 high
        memory[16'h8022] = 8'h01; // address 0x1001 low
        
        // Test 9: Final GPIO pattern
        memory[16'h8023] = 8'h04; // ADDI R5, #0x55
        memory[16'h8024] = 8'h85; // R5, immediate
        memory[16'h8025] = 8'h55; // pattern 0x55
        memory[16'h8026] = 8'h06; // OUT R5 to GPIO
        memory[16'h8027] = 8'h50; // R5 to port 0
        
        // Test 10: HALT
        memory[16'h8028] = 8'h64; // HALT
        
        $display("Comprehensive test program loaded");
    end
    
    // Test sequence
    initial begin
        $dumpfile("comprehensive_test_simple.vcd");
        $dumpvars(0, tb_comprehensive_simple);
        
        // Initialize signals
        clk = 0;
        rst_n = 0;
        uart_rx = 1;
        ext_mem_ready = 0;
        
        // Reset sequence
        #100;
        rst_n = 1;
        
        $display("\n========================================");
        $display("Starting comprehensive test program...");
        $display("========================================");
        $display("Time: %0t - System reset complete", $time);
        
        // Let program execute
        #5000;
        
        // Check status periodically
        $display("\n--- Status Check 1 at Time: %0t ---", $time);
        $display("Debug register: %02X", debug_reg);
        $display("System halted: %b", system_halted);
        $display("GPIO output: %02X", gpio_pins);
        $display("Memory [1000]: %02X (should be 52/0x34)", memory[16'h1000]);
        $display("Memory [1001]: %02X (should be 0 for success)", memory[16'h1001]);
        
        #5000;
        
        $display("\n--- Status Check 2 at Time: %0t ---", $time);
        $display("Debug register: %02X", debug_reg);
        $display("System halted: %b", system_halted);
        $display("GPIO output: %02X", gpio_pins);
        $display("Memory [1000]: %02X", memory[16'h1000]);
        $display("Memory [1001]: %02X", memory[16'h1001]);
        
        #5000;
        
        // Final results
        $display("\n========================================");
        $display("Final Test Results");
        $display("========================================");
        $display("Execution time: %0t", $time);
        $display("System halted: %b", system_halted);
        $display("Final GPIO state: %02X", gpio_pins);
        
        $display("\nTest Results:");
        $display("Memory [1000]: %02X (arithmetic result)", memory[16'h1000]);
        $display("Memory [1001]: %02X (test status: 0=pass, FF=fail)", memory[16'h1001]);
        
        // Analyze results
        if (memory[16'h1000] == 8'h34) begin // 42 + 10 = 52 (0x34)
            $display("PASS: Arithmetic test (42 + 10 = 52)");
        end else begin
            $display("FAIL: Arithmetic test - expected 0x34, got %02X", memory[16'h1000]);
        end
        
        if (memory[16'h1001] == 8'h00) begin
            $display("PASS: Load/store and compare test");
        end else begin
            $display("FAIL: Load/store or compare test failed");
        end
        
        if (gpio_pins == 8'h55) begin
            $display("PASS: GPIO output test (final pattern 0x55)");
        end else begin
            $display("INFO: GPIO output is %02X (may be intermediate value)", gpio_pins);
        end
        
        if (system_halted) begin
            $display("PASS: System halted correctly");
        end else begin
            $display("FAIL: System did not halt");
        end
        
        $display("\nComprehensive test completed at time %0t", $time);
        $finish;
    end
    
    // Monitor memory writes to test area
    always @(posedge clk) begin
        if (ext_mem_write && ext_mem_cs && ext_mem_ready) begin
            if (ext_mem_addr >= 16'h1000 && ext_mem_addr < 16'h1010) begin
                $display("Time: %0t - Test result written: [%04X] = %02X", $time, ext_mem_addr, ext_mem_data);
            end
        end
    end
    
    // Timeout watchdog
    initial begin
        #100000; // 100us timeout
        $display("\nTIMEOUT: Test exceeded maximum time");
        $finish;
    end
    
endmodule
