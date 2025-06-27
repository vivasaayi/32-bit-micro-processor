// ALU Test Module

module tb_alu_test;

reg [7:0] a, b;
reg [3:0] op;
reg [7:0] flags_in;
wire [7:0] result;
wire [7:0] flags_out;

// ALU operation codes
localparam ALU_ADD = 4'h0;
localparam ALU_SUB = 4'h1;
localparam ALU_AND = 4'h4;
localparam ALU_OR  = 4'h5;
localparam ALU_XOR = 4'h6;

// Instantiate ALU
alu dut (
    .a(a),
    .b(b),
    .op(op),
    .flags_in(flags_in),
    .result(result),
    .flags_out(flags_out)
);

// Test sequence
initial begin
    $display("=== ALU Test ===");
    
    flags_in = 8'h00;
    
    // Test ADD
    a = 8'h2A; // 42
    b = 8'h0A; // 10
    op = ALU_ADD;
    #10;
    $display("ADD: %d + %d = %d (0x%h)", a, b, result, result);
    
    // Test SUB
    a = 8'h32; // 50
    b = 8'h14; // 20
    op = ALU_SUB;
    #10;
    $display("SUB: %d - %d = %d (0x%h)", a, b, result, result);
    
    // Test AND
    a = 8'hFF;
    b = 8'h0F;
    op = ALU_AND;
    #10;
    $display("AND: 0x%h & 0x%h = 0x%h", a, b, result);
    
    // Test OR
    a = 8'hF0;
    b = 8'h0F;
    op = ALU_OR;
    #10;
    $display("OR:  0x%h | 0x%h = 0x%h", a, b, result);
    
    // Test XOR
    a = 8'hAA;
    b = 8'h55;
    op = ALU_XOR;
    #10;
    $display("XOR: 0x%h ^ 0x%h = 0x%h", a, b, result);
    
    $display("ALU test completed successfully!");
    $finish;
end

endmodule
