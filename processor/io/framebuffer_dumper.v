/**
 * Framebuffer Dumper Module
 * 
 * Periodically dumps the framebuffer memory to a file for visualization
 * by the Java UI viewer.
 */

module framebuffer_dumper #(
    parameter FRAME_WIDTH = 320,
    parameter FRAME_HEIGHT = 240,
    parameter DUMP_INTERVAL = 1000000  // Clock cycles between dumps
) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    
    // Memory interface to read framebuffer
    output reg [31:0] fb_addr,
    input wire [31:0] fb_data,
    output reg fb_read,
    input wire fb_ready,
    
    // Control signals
    input wire [31:0] framebuffer_base_addr,
    output reg dump_complete
);

    // State machine for dumping
    localparam [2:0] IDLE = 3'b000,
                     DUMP_HEADER = 3'b001,
                     DUMP_PIXEL = 3'b010,
                     DUMP_COMPLETE = 3'b011;
    
    reg [2:0] state, next_state;
    reg [31:0] dump_counter;
    reg [31:0] pixel_x, pixel_y;
    reg [31:0] pixel_count;
    
    integer dump_file;
    reg file_open;
    
    // Dump timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dump_counter <= 0;
            state <= IDLE;
            pixel_x <= 0;
            pixel_y <= 0;
            pixel_count <= 0;
            fb_addr <= 0;
            fb_read <= 0;
            dump_complete <= 0;
            file_open <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (enable) begin
                        dump_counter <= dump_counter + 1;
                        if (dump_counter >= DUMP_INTERVAL) begin
                            dump_counter <= 0;
                            pixel_x <= 0;
                            pixel_y <= 0;
                            pixel_count <= 0;
                            dump_complete <= 0;
                            
                            // Open file for writing
                            if (!file_open) begin
                                dump_file = $fopen("temp/reports/framebuffer.ppm", "w");
                                file_open <= 1;
                            end
                        end
                    end
                end
                
                DUMP_HEADER: begin
                    if (file_open) begin
                        $fwrite(dump_file, "P6\n");
                        $fwrite(dump_file, "# RISC CPU Framebuffer\n");
                        $fwrite(dump_file, "%d %d\n", FRAME_WIDTH, FRAME_HEIGHT);
                        $fwrite(dump_file, "255\n");
                    end
                end
                
                DUMP_PIXEL: begin
                    if (fb_ready && file_open) begin
                        // Extract RGB from 32-bit data (assuming RGBA8888 format)
                        // Format: [31:24] = R, [23:16] = G, [15:8] = B, [7:0] = A
                        $fwrite(dump_file, "%c%c%c", 
                               fb_data[31:24], fb_data[23:16], fb_data[15:8]);
                        
                        pixel_count <= pixel_count + 1;
                        pixel_x <= pixel_x + 1;
                        
                        if (pixel_x >= FRAME_WIDTH - 1) begin
                            pixel_x <= 0;
                            pixel_y <= pixel_y + 1;
                        end
                        
                        // Calculate next address
                        fb_addr <= framebuffer_base_addr + (pixel_count + 1) * 4;
                    end
                end
                
                DUMP_COMPLETE: begin
                    if (file_open) begin
                        $fclose(dump_file);
                        file_open <= 0;
                    end
                    dump_complete <= 1;
                    $display("Framebuffer dump complete: %d x %d pixels", FRAME_WIDTH, FRAME_HEIGHT);
                end
            endcase
            
            // Memory read control
            if (state == DUMP_PIXEL && !fb_read) begin
                fb_read <= 1;
                fb_addr <= framebuffer_base_addr + pixel_count * 4;
            end else if (state != DUMP_PIXEL) begin
                fb_read <= 0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (enable && dump_counter >= DUMP_INTERVAL) begin
                    next_state = DUMP_HEADER;
                end else begin
                    next_state = IDLE;
                end
            end
            
            DUMP_HEADER: begin
                next_state = DUMP_PIXEL;
            end
            
            DUMP_PIXEL: begin
                if (pixel_count >= FRAME_WIDTH * FRAME_HEIGHT - 1) begin
                    next_state = DUMP_COMPLETE;
                end else begin
                    next_state = DUMP_PIXEL;
                end
            end
            
            DUMP_COMPLETE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule

/**
 * Simple Display Buffer for Testing
 * 
 * A simple framebuffer that can be written to by the CPU
 * and read by the framebuffer dumper.
 */
module display_buffer #(
    parameter FRAME_WIDTH = 320,
    parameter FRAME_HEIGHT = 240,
    parameter BASE_ADDR = 32'h10000
) (
    input wire clk,
    input wire rst_n,
    
    // CPU interface
    input wire [31:0] cpu_addr,
    inout wire [31:0] cpu_data,
    input wire cpu_read,
    input wire cpu_write,
    output reg cpu_ready,
    
    // Framebuffer dumper interface
    input wire [31:0] fb_addr,
    output reg [31:0] fb_data,
    input wire fb_read,
    output reg fb_ready
);

    // Memory array for framebuffer
    reg [31:0] framebuffer [0:FRAME_WIDTH*FRAME_HEIGHT-1];
    
    wire [31:0] cpu_offset = cpu_addr - BASE_ADDR;
    wire [31:0] fb_offset = fb_addr - BASE_ADDR;
    wire [15:0] cpu_pixel_index = cpu_offset[17:2];  // Divide by 4 for word addressing
    wire [15:0] fb_pixel_index = fb_offset[17:2];
    
    // CPU access
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_ready <= 0;
            // Initialize framebuffer with test pattern
            for (i = 0; i < FRAME_WIDTH * FRAME_HEIGHT; i = i + 1) begin
                framebuffer[i] <= 32'h00000000; // Black
            end
        end else begin
            cpu_ready <= 0;
            
            if (cpu_addr >= BASE_ADDR && cpu_addr < BASE_ADDR + FRAME_WIDTH * FRAME_HEIGHT * 4) begin
                if (cpu_write && cpu_pixel_index < FRAME_WIDTH * FRAME_HEIGHT) begin
                    framebuffer[cpu_pixel_index] <= cpu_data;
                    cpu_ready <= 1;
                    $display("Display: Pixel[%d,%d] = 0x%08x", 
                            cpu_pixel_index % FRAME_WIDTH,
                            cpu_pixel_index / FRAME_WIDTH,
                            cpu_data);
                end else if (cpu_read && cpu_pixel_index < FRAME_WIDTH * FRAME_HEIGHT) begin
                    cpu_ready <= 1;
                end
            end
        end
    end
    
    // CPU read data
    assign cpu_data = (cpu_read && cpu_addr >= BASE_ADDR && 
                      cpu_addr < BASE_ADDR + FRAME_WIDTH * FRAME_HEIGHT * 4) ?
                     framebuffer[cpu_pixel_index] : 32'hZZZZZZZZ;
    
    // Framebuffer dumper access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fb_data <= 0;
            fb_ready <= 0;
        end else begin
            fb_ready <= 0;
            
            if (fb_read && fb_addr >= BASE_ADDR && 
                fb_addr < BASE_ADDR + FRAME_WIDTH * FRAME_HEIGHT * 4) begin
                fb_data <= framebuffer[fb_pixel_index];
                fb_ready <= 1;
            end
        end
    end

endmodule
