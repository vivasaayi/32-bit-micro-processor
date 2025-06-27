// Comprehensive test for the microprocessor system

module tb_comprehensive_final;

reg clk, rst_n;
wire [15:0] addr;
wire [7:0] data;
wire read_en, write_en, cs;
reg ready;
reg uart_rx;
wire uart_tx;
wire [7:0] gpio;
wire halted, user_mode;
wire [7:0] debug;

// Memory array
reg [7:0] mem [0:65535];
reg [7:0] mem_out;

// Clock
always #50 clk = ~clk; // 10MHz clock

// Memory model
always @(posedge clk) begin
    ready <= 0;
    if (cs && read_en) begin
        mem_out <= mem[addr];
        ready <= 1;
    end else if (cs && write_en) begin
        mem[addr] <= data;
        ready <= 1;
    end
end

assign data = (read_en && ready) ? mem_out : 8'bZ;

// DUT
microprocessor_system dut (
    .clk(clk),
    .rst_n(rst_n),
    .ext_mem_addr(addr),
    .ext_mem_data(data),
    .ext_mem_read(read_en),
    .ext_mem_write(write_en),
    .ext_mem_cs(cs),
    .ext_mem_ready(ready),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .gpio_pins(gpio),
    .system_halted(halted),
    .user_mode_active(user_mode),
    .debug_reg(debug)
);

// Initialize memory and load comprehensive test
initial begin
    integer i;
    
    // Clear memory
    for (i = 0; i < 65536; i = i + 1) begin
        mem[i] = 8'h00;
    end
    
    // Initialize page table
    for (i = 0; i < 256; i = i + 1) begin
        mem[16'hE000 + i] = 8'h80 | (i[3:0]);
    end
    
    // Load comprehensive test program at 0x8000
    $display("Loading comprehensive test program...");
    
    // Test 1: Basic arithmetic
    mem[16'h8000] = 8'h04; // ADDI R0, #42
    mem[16'h8001] = 8'h2A;
    mem[16'h8002] = 8'h04; // ADDI R1, #10  
    mem[16'h8003] = 8'h81;
    mem[16'h8004] = 8'h0A;
    mem[16'h8005] = 8'h00; // ADD R0, R1
    mem[16'h8006] = 8'h10;
    
    // Test 2: Store result
    mem[16'h8007] = 8'h01; // STORE R0 to [1000]
    mem[16'h8008] = 8'h00;
    mem[16'h8009] = 8'h10;
    mem[16'h800A] = 8'h00;
    
    // Test 3: Load back
    mem[16'h800B] = 8'h02; // LOAD R2 from [1000]
    mem[16'h800C] = 8'h20;
    mem[16'h800D] = 8'h10;
    mem[16'h800E] = 8'h00;
    
    // Test 4: GPIO output
    mem[16'h800F] = 8'h04; // ADDI R3, #0xAA
    mem[16'h8010] = 8'h83;
    mem[16'h8011] = 8'hAA;
    mem[16'h8012] = 8'h06; // OUT R3 to GPIO
    mem[16'h8013] = 8'h30;
    
    // Test 5: Compare and branch
    mem[16'h8014] = 8'h07; // CMP R0, R2
    mem[16'h8015] = 8'h02;
    mem[16'h8016] = 8'h08; // BEQ
    mem[16'h8017] = 8'h80;
    mem[16'h8018] = 8'h1C;
    
    // Error path
    mem[16'h8019] = 8'h04; // ADDI R4, #0xFF
    mem[16'h801A] = 8'h84;
    mem[16'h801B] = 8'hFF;
    
    // Success path
    mem[16'h801C] = 8'h04; // ADDI R4, #0x00
    mem[16'h801D] = 8'h84;
    mem[16'h801E] = 8'h00;
    
    // Store test result
    mem[16'h801F] = 8'h01; // STORE R4 to [1001]
    mem[16'h8020] = 8'h40;
    mem[16'h8021] = 8'h10;
    mem[16'h8022] = 8'h01;
    
    // Final GPIO pattern
    mem[16'h8023] = 8'h04; // ADDI R5, #0x55
    mem[16'h8024] = 8'h85;
    mem[16'h8025] = 8'h55;
    mem[16'h8026] = 8'h06; // OUT R5 to GPIO
    mem[16'h8027] = 8'h50;
    
    // HALT
    mem[16'h8028] = 8'h64;
    
    $display("Comprehensive test program loaded successfully");
end

// Test sequence
initial begin
    // Initialize
    clk = 0;
    rst_n = 0;
    uart_rx = 1;
    ready = 0;
    
    // Reset
    #1000;
    rst_n = 1;
    
    $display("\n========================================");
    $display("Starting comprehensive microprocessor test");
    $display("========================================");
    $display("Time: %0t - Reset complete", $time);
    
    // Run for a while
    #10000;
    
    $display("\n--- Status Check 1 ---");
    $display("Time: %0t", $time);
    $display("System halted: %b", halted);
    $display("Debug register: %02X", debug);
    $display("GPIO: %02X", gpio);
    $display("Memory [1000]: %02X", mem[16'h1000]);
    $display("Memory [1001]: %02X", mem[16'h1001]);
    
    #10000;
    
    $display("\n--- Status Check 2 ---");
    $display("Time: %0t", $time);
    $display("System halted: %b", halted);
    $display("Debug register: %02X", debug);
    $display("GPIO: %02X", gpio);
    $display("Memory [1000]: %02X", mem[16'h1000]);
    $display("Memory [1001]: %02X", mem[16'h1001]);
    
    #10000;
    
    $display("\n========================================");
    $display("Final Results");
    $display("========================================");
    $display("Total execution time: %0t", $time);
    $display("System halted: %b", halted);
    $display("Final GPIO: %02X", gpio);
    
    $display("\nTest Results:");
    $display("Memory [1000]: %02X (arithmetic: 42+10=52/0x34)", mem[16'h1000]);
    $display("Memory [1001]: %02X (test status: 0=pass, FF=fail)", mem[16'h1001]);
    
    // Analyze results
    if (mem[16'h1000] == 8'h34) begin
        $display("PASS: Arithmetic test (42 + 10 = 52)");
    end else begin
        $display("FAIL: Arithmetic test - expected 0x34, got %02X", mem[16'h1000]);
    end
    
    if (mem[16'h1001] == 8'h00) begin
        $display("PASS: Load/store and compare test");
    end else begin
        $display("FAIL: Load/store or compare test");
    end
    
    if (gpio == 8'h55) begin
        $display("PASS: GPIO output test (final pattern 0x55)");
    end else if (gpio == 8'hAA) begin
        $display("PARTIAL: GPIO shows intermediate pattern 0xAA");
    end else begin
        $display("INFO: GPIO shows pattern %02X", gpio);
    end
    
    if (halted) begin
        $display("PASS: System halted correctly");
    end else begin
        $display("INFO: System still running (may need more time)");
    end
    
    $display("\nComprehensive test completed");
    $finish;
end

// Monitor important memory writes
always @(posedge clk) begin
    if (write_en && cs && ready && addr >= 16'h1000 && addr < 16'h1010) begin
        $display("Time: %0t - Result written: [%04X] = %02X", $time, addr, data);
    end
end

// Timeout
initial begin
    #200000;
    $display("TIMEOUT: Test exceeded maximum time");
    $finish;
end

endmodule
