// Simple system test that should work with Icarus Verilog

module tb_system_basic;

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
reg [7:0] mem [0:1023]; // Small memory for testing
reg [7:0] mem_out;

// Clock
always #50 clk = ~clk; // 10MHz clock

// Memory model
always @(posedge clk) begin
    ready <= 0;
    if (cs && read_en && addr < 1024) begin
        mem_out <= mem[addr];
        ready <= 1;
    end else if (cs && write_en && addr < 1024) begin
        mem[addr] <= data;
        ready <= 1;
    end
end

assign data = (read_en && ready) ? mem_out : 8'bZ;

// DUT - simplified version
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

// Test
initial begin
    $display("Starting basic system test...");
    
    clk = 0;
    rst_n = 0;
    uart_rx = 1;
    ready = 0;
    
    // Clear memory
    mem[0] = 8'h64; // HALT instruction at address 0
    mem[1] = 8'h00;
    
    #1000 rst_n = 1;
    $display("Reset released");
    
    #5000;
    $display("Test complete");
    $display("Halted: %b", halted);
    $finish;
end

endmodule
