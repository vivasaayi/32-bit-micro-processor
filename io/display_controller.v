`timescale 1ns / 1ps

//
// Display Controller for Custom RISC Processor
// Supports both text mode (CLI) and graphics mode (pixels)
//

module display_controller (
    input wire clk,
    input wire reset,
    
    // Processor interface (memory-mapped)
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output reg [31:0] read_data,
    input wire write_enable,
    input wire read_enable,
    input wire [3:0] byte_enable,
    
    // VGA output
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [7:0] vga_red,
    output wire [7:0] vga_green,
    output wire [7:0] vga_blue,
    output wire vga_blank,
    
    // Status signals
    output wire display_ready,
    output wire frame_complete
);

    // Display modes
    localparam MODE_TEXT     = 2'b00;
    localparam MODE_GRAPHICS = 2'b01;
    localparam MODE_MIXED    = 2'b10;
    
    // Memory map
    localparam CTRL_BASE     = 32'hFF000000;
    localparam TEXT_BASE     = 32'hFF001000;
    localparam GRAPHICS_BASE = 32'hFF002000;
    localparam PALETTE_BASE  = 32'hFF050000;
    
    // VGA timing (640x480 @ 60Hz)
    localparam H_DISPLAY     = 640;
    localparam H_FRONT_PORCH = 16;
    localparam H_SYNC_PULSE  = 96;
    localparam H_BACK_PORCH  = 48;
    localparam H_TOTAL       = 800;
    
    localparam V_DISPLAY     = 480;
    localparam V_FRONT_PORCH = 10;
    localparam V_SYNC_PULSE  = 2;
    localparam V_BACK_PORCH  = 33;
    localparam V_TOTAL       = 525;
    
    // Text mode parameters
    localparam TEXT_COLS     = 80;
    localparam TEXT_ROWS     = 25;
    localparam CHAR_WIDTH    = 8;
    localparam CHAR_HEIGHT   = 16;
    
    // Control registers
    reg [1:0] mode_reg;
    reg [6:0] cursor_x;
    reg [4:0] cursor_y;
    reg [7:0] text_color;
    reg [9:0] graphics_x;
    reg [8:0] graphics_y;
    reg [7:0] pixel_color;
    reg [7:0] status_reg;
    
    // VGA timing counters
    reg [9:0] h_counter;
    reg [9:0] v_counter;
    
    // Display signals
    wire h_active = (h_counter < H_DISPLAY);
    wire v_active = (v_counter < V_DISPLAY);
    wire display_active = h_active && v_active;
    
    assign vga_hsync = ~((h_counter >= H_DISPLAY + H_FRONT_PORCH) && 
                         (h_counter < H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE));
    assign vga_vsync = ~((v_counter >= V_DISPLAY + V_FRONT_PORCH) && 
                         (v_counter < V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE));
    assign vga_blank = ~display_active;
    
    // Memory blocks
    // Text buffer: 80x25 characters (each char is 16 bits: 8-bit char + 8-bit attr)
    reg [15:0] text_buffer [0:TEXT_COLS*TEXT_ROWS-1];
    
    // Graphics framebuffer: 640x480 pixels (8-bit color)
    reg [7:0] framebuffer [0:H_DISPLAY*V_DISPLAY-1];
    
    // Color palette: 256 colors (24-bit RGB)
    reg [23:0] palette [0:255];
    
    // Character ROM (8x16 font)
    reg [7:0] char_rom [0:4095]; // 256 characters x 16 rows
    
    // VGA timing generation
    always @(posedge clk) begin
        if (reset) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                h_counter <= 0;
                if (v_counter == V_TOTAL - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end
    
    // Frame complete signal
    assign frame_complete = (h_counter == 0) && (v_counter == 0);
    assign display_ready = 1'b1; // Always ready for now
    
    // Text mode character position calculation
    wire [6:0] text_col = h_counter[9:3]; // h_counter / 8
    wire [4:0] text_row = v_counter[8:4]; // v_counter / 16
    wire [2:0] char_x = h_counter[2:0];   // h_counter % 8
    wire [3:0] char_y = v_counter[3:0];   // v_counter % 16
    wire [12:0] text_addr = text_row * TEXT_COLS + text_col;
    
    // Character and attribute from text buffer
    wire [15:0] text_data = text_buffer[text_addr];
    wire [7:0] character = text_data[7:0];
    wire [7:0] attribute = text_data[15:8];
    
    // Character ROM lookup
    wire [11:0] char_rom_addr = {character, char_y};
    wire [7:0] char_bitmap = char_rom[char_rom_addr];
    wire char_pixel = char_bitmap[7-char_x];
    
    // Cursor display
    wire cursor_active = (text_col == cursor_x) && (text_row == cursor_y) && 
                        (char_y >= 14) && (char_y <= 15);
    
    // Graphics mode pixel calculation
    wire [18:0] pixel_addr = v_counter * H_DISPLAY + h_counter;
    wire [7:0] graphics_pixel = framebuffer[pixel_addr];
    
    // Mixed mode signals
    wire [4:0] mixed_text_row = (v_counter >= 400) ? ((v_counter - 400) >> 4) : 5'b0;
    wire [12:0] mixed_text_addr = mixed_text_row * TEXT_COLS + text_col;
    wire [15:0] mixed_text_data = text_buffer[mixed_text_addr];
    wire [7:0] mixed_char = mixed_text_data[7:0];
    wire [7:0] mixed_attr = mixed_text_data[15:8];
    wire [11:0] mixed_char_rom_addr = {mixed_char, char_y};
    wire [7:0] mixed_char_bitmap = char_rom[mixed_char_rom_addr];
    wire mixed_char_pixel = mixed_char_bitmap[7-char_x];
    
    // Color output generation
    reg [7:0] color_index;
    
    always @(*) begin
        if (!display_active) begin
            color_index = 8'h00; // Black during blanking
        end else begin
            case (mode_reg)
                MODE_TEXT: begin
                    if (cursor_active) begin
                        color_index = 8'hFF; // White cursor
                    end else if (char_pixel) begin
                        color_index = attribute[3:0]; // Foreground color
                    end else begin
                        color_index = attribute[7:4]; // Background color
                    end
                end
                
                MODE_GRAPHICS: begin
                    color_index = graphics_pixel;
                end
                
                MODE_MIXED: begin
                    // Mixed mode: graphics with text overlay
                    if (v_counter >= 400) begin
                        // Text area at bottom
                        if (mixed_char_pixel) begin
                            color_index = mixed_attr[3:0];
                        end else begin
                            color_index = mixed_attr[7:4];
                        end
                    end else begin
                        // Graphics area
                        color_index = graphics_pixel;
                    end
                end
                
                default: color_index = 8'h00;
            endcase
        end
    end
    
    // Palette lookup
    wire [23:0] rgb_color = palette[color_index];
    assign vga_red   = rgb_color[23:16];
    assign vga_green = rgb_color[15:8];
    assign vga_blue  = rgb_color[7:0];
    
    // Memory interface
    always @(posedge clk) begin
        if (reset) begin
            mode_reg <= MODE_TEXT;
            cursor_x <= 0;
            cursor_y <= 0;
            text_color <= 8'h0F; // White on black
            graphics_x <= 0;
            graphics_y <= 0;
            pixel_color <= 8'hFF;
            status_reg <= 8'h01; // Ready
            read_data <= 32'h0;
        end else begin
            // Handle processor memory access
            if (write_enable) begin
                case (addr & 32'hFFFFF000)
                    CTRL_BASE: begin
                        case (addr & 32'h00000FFF)
                            12'h000: mode_reg <= write_data[1:0];
                            12'h004: cursor_x <= write_data[6:0];
                            12'h008: cursor_y <= write_data[4:0];
                            12'h00C: text_color <= write_data[7:0];
                            12'h010: graphics_x <= write_data[9:0];
                            12'h014: graphics_y <= write_data[8:0];
                            12'h018: pixel_color <= write_data[7:0];
                        endcase
                    end
                    
                    TEXT_BASE: begin
                        // Text buffer write
                        if ((addr - TEXT_BASE) < (TEXT_COLS*TEXT_ROWS*2)) begin
                            if (byte_enable[0]) text_buffer[(addr - TEXT_BASE) >> 1][7:0] <= write_data[7:0];
                            if (byte_enable[1]) text_buffer[(addr - TEXT_BASE) >> 1][15:8] <= write_data[15:8];
                        end
                    end
                    
                    GRAPHICS_BASE: begin
                        // Framebuffer write
                        if ((addr - GRAPHICS_BASE) < (H_DISPLAY*V_DISPLAY) && byte_enable[0]) begin
                            framebuffer[addr - GRAPHICS_BASE] <= write_data[7:0];
                        end
                    end
                    
                    PALETTE_BASE: begin
                        // Palette write
                        palette[(addr - PALETTE_BASE) >> 2] <= write_data[23:0];
                    end
                endcase
            end
            
            if (read_enable) begin
                case (addr & 32'hFFFFF000)
                    CTRL_BASE: begin
                        case (addr & 32'h00000FFF)
                            12'h000: read_data <= {30'b0, mode_reg};
                            12'h004: read_data <= {25'b0, cursor_x};
                            12'h008: read_data <= {27'b0, cursor_y};
                            12'h00C: read_data <= {24'b0, text_color};
                            12'h010: read_data <= {22'b0, graphics_x};
                            12'h014: read_data <= {23'b0, graphics_y};
                            12'h018: read_data <= {24'b0, pixel_color};
                            12'h01C: read_data <= {24'b0, status_reg};
                            default: read_data <= 32'h0;
                        endcase
                    end
                    
                    TEXT_BASE: begin
                        if ((addr - TEXT_BASE) < (TEXT_COLS*TEXT_ROWS*2)) begin
                            read_data <= {16'b0, text_buffer[(addr - TEXT_BASE) >> 1]};
                        end else begin
                            read_data <= 32'h0;
                        end
                    end
                    
                    GRAPHICS_BASE: begin
                        if ((addr - GRAPHICS_BASE) < (H_DISPLAY*V_DISPLAY)) begin
                            read_data <= {24'b0, framebuffer[addr - GRAPHICS_BASE]};
                        end else begin
                            read_data <= 32'h0;
                        end
                    end
                    
                    PALETTE_BASE: begin
                        read_data <= {8'b0, palette[(addr - PALETTE_BASE) >> 2]};
                    end
                    
                    default: read_data <= 32'h0;
                endcase
            end
        end
    end
    
    // Initialize character ROM with basic 8x16 font
    initial begin
        $readmemh("../io/char_rom.hex", char_rom);
    end
    
    // Initialize default palette
    integer k;
    initial begin
        // Standard 16-color palette
        palette[0]  = 24'h000000; // Black
        palette[1]  = 24'h000080; // Dark Blue
        palette[2]  = 24'h008000; // Dark Green
        palette[3]  = 24'h008080; // Dark Cyan
        palette[4]  = 24'h800000; // Dark Red
        palette[5]  = 24'h800080; // Dark Magenta
        palette[6]  = 24'h808000; // Brown
        palette[7]  = 24'hC0C0C0; // Light Gray
        palette[8]  = 24'h808080; // Dark Gray
        palette[9]  = 24'h0000FF; // Blue
        palette[10] = 24'h00FF00; // Green
        palette[11] = 24'h00FFFF; // Cyan
        palette[12] = 24'hFF0000; // Red
        palette[13] = 24'hFF00FF; // Magenta
        palette[14] = 24'hFFFF00; // Yellow
        palette[15] = 24'hFFFFFF; // White
        
        // Initialize remaining palette entries with grayscale
        for (k = 16; k < 256; k = k + 1) begin
            palette[k] = {k[7:0], k[7:0], k[7:0]};
        end
    end
    
    // Clear text buffer on reset
    integer j;
    always @(posedge clk) begin
        if (reset) begin
            for (j = 0; j < TEXT_COLS*TEXT_ROWS; j = j + 1) begin
                text_buffer[j] <= 16'h0720; // Space character with default attributes
            end
        end
    end

endmodule
