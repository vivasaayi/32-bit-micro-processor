`timescale 1ns / 1ps

module tb_system_with_display;

    // Testbench signals
    reg clk;
    reg reset;
    
    // VGA outputs
    wire vga_hsync, vga_vsync;
    wire [7:0] vga_red, vga_green, vga_blue;
    wire vga_blank;
    wire cpu_running, display_active;
    
    // System instance
    microprocessor_system_with_display system (
        .clk(clk),
        .reset(reset),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_red(vga_red),
        .vga_green(vga_green),
        .vga_blue(vga_blue),
        .vga_blank(vga_blank),
        .cpu_running(cpu_running),
        .display_active(display_active)
    );
    
    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // VGA timing monitoring
    integer h_count = 0;
    integer v_count = 0;
    integer frame_count = 0;
    
    // Monitor VGA timing
    always @(posedge clk) begin
        if (!vga_hsync) h_count <= 0;
        else h_count <= h_count + 1;
        
        if (!vga_vsync) begin
            v_count <= 0;
            if (frame_count < 5) begin
                $display("Frame %d completed", frame_count);
                frame_count <= frame_count + 1;
            end
        end else if (!vga_hsync) begin
            v_count <= v_count + 1;
        end
    end
    
    // Test sequence
    initial begin
        $display("=== Enhanced Microprocessor System Test ===");
        $dumpfile("system_with_display.vcd");
        $dumpvars(0, tb_system_with_display);
        
        // Initialize
        reset = 1;
        #100;
        reset = 0;
        
        $display("System started:");
        $display("  CPU running: %b", cpu_running);
        $display("  Display active: %b", display_active);
        
        // Run for several VGA frames
        #33000000; // About 5 frames at 60Hz
        
        $display("Test completed after 5 VGA frames");
        $display("Final status:");
        $display("  CPU running: %b", cpu_running);
        $display("  Display active: %b", display_active);
        $display("  Last VGA RGB: R=%d G=%d B=%d", vga_red, vga_green, vga_blue);
        
        $finish;
    end
    
    // Monitor display activity
    always @(posedge clk) begin
        if (!vga_blank && (vga_red > 0 || vga_green > 0 || vga_blue > 0)) begin
            // Log some display activity (not too verbose)
            if (h_count % 100 == 0 && v_count % 100 == 0) begin
                //$display("Display pixel at (%d,%d): RGB=(%d,%d,%d)", 
                //         h_count, v_count, vga_red, vga_green, vga_blue);
            end
        end
    end

endmodule
