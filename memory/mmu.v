/**
 * Memory Management Unit (MMU)
 * 
 * Provides virtual memory support for the 8-bit microprocessor.
 * Essential for running a Linux-like operating system.
 * 
 * Features:
 * - Virtual to physical address translation
 * - Page-based memory management (256-byte pages)
 * - User/kernel mode protection
 * - Memory protection flags
 * - TLB (Translation Lookaside Buffer)
 */

module mmu (
    input wire clk,
    input wire rst_n,
    
    // CPU interface
    input wire [15:0] virtual_addr,
    output wire [15:0] physical_addr,
    input wire mem_read,
    input wire mem_write,
    input wire user_mode,
    
    // Status outputs
    output wire page_fault,
    output wire protection_violation,
    output wire translation_valid,
    
    // MMU control interface
    input wire [15:0] page_table_base,
    input wire mmu_enable,
    input wire tlb_flush,
    
    // Memory interface for page table access
    output wire [15:0] pt_addr,
    input wire [7:0] pt_data,
    output wire pt_read,
    input wire pt_ready
);

    // Page size is 256 bytes (8-bit page offset)
    localparam PAGE_SIZE_BITS = 8;
    localparam PAGE_TABLE_ENTRIES = 256; // 8-bit page number
    
    // Virtual address breakdown
    wire [7:0] page_number;
    wire [7:0] page_offset;
    
    assign page_number = virtual_addr[15:8];
    assign page_offset = virtual_addr[7:0];
    
    // Page Table Entry (PTE) format (8-bit)
    // Bit 7: Valid
    // Bit 6: User accessible  
    // Bit 5: Writable
    // Bit 4: Executable
    // Bits 3-0: Physical page number (high 4 bits)
    
    localparam PTE_VALID_BIT = 7;
    localparam PTE_USER_BIT = 6;
    localparam PTE_WRITE_BIT = 5;
    localparam PTE_EXEC_BIT = 4;
    
    // TLB - 4 entry direct mapped cache
    reg [7:0] tlb_vpn [0:3];        // Virtual page number
    reg [7:0] tlb_pte [0:3];        // Page table entry
    reg [3:0] tlb_valid;            // Valid bits
    
    // TLB lookup signals
    wire [1:0] tlb_index;
    wire tlb_hit;
    wire [7:0] tlb_pte_out;
    
    assign tlb_index = page_number[1:0]; // Use lower 2 bits for 4-entry TLB
    assign tlb_hit = tlb_valid[tlb_index] && (tlb_vpn[tlb_index] == page_number);
    assign tlb_pte_out = tlb_pte[tlb_index];
    
    // Page table walk state machine
    localparam PT_IDLE = 2'b00;
    localparam PT_READ = 2'b01;
    localparam PT_WAIT = 2'b10;
    localparam PT_DONE = 2'b11;
    
    reg [1:0] pt_state, pt_next_state;
    reg [7:0] current_pte;
    reg pt_walk_complete;
    
    // Address translation
    reg [7:0] physical_page;
    reg [15:0] translated_addr;
    reg translation_error;
    reg protection_error;
    
    always @(*) begin
        if (!mmu_enable) begin
            // MMU disabled - direct mapping
            translated_addr = virtual_addr;
            translation_error = 1'b0;
            protection_error = 1'b0;
            physical_page = virtual_addr[15:8];
        end else if (tlb_hit) begin
            // TLB hit - use cached translation
            current_pte = tlb_pte_out;
            if (current_pte[PTE_VALID_BIT]) begin
                physical_page = {current_pte[3:0], 4'b0000}; // Extend to 8 bits
                translated_addr = {physical_page, page_offset};
                translation_error = 1'b0;
                
                // Check protection
                if (user_mode && !current_pte[PTE_USER_BIT]) begin
                    protection_error = 1'b1; // User accessing kernel page
                end else if (mem_write && !current_pte[PTE_WRITE_BIT]) begin
                    protection_error = 1'b1; // Write to read-only page
                end else begin
                    protection_error = 1'b0;
                end
            end else begin
                translation_error = 1'b1;
                protection_error = 1'b0;
                translated_addr = 16'h0000;
                physical_page = 8'h00;
            end
        end else begin
            // TLB miss - need page table walk
            if (pt_walk_complete) begin
                if (current_pte[PTE_VALID_BIT]) begin
                    physical_page = {current_pte[3:0], 4'b0000};
                    translated_addr = {physical_page, page_offset};
                    translation_error = 1'b0;
                    
                    // Check protection
                    if (user_mode && !current_pte[PTE_USER_BIT]) begin
                        protection_error = 1'b1;
                    end else if (mem_write && !current_pte[PTE_WRITE_BIT]) begin
                        protection_error = 1'b1;
                    end else begin
                        protection_error = 1'b0;
                    end
                end else begin
                    translation_error = 1'b1;
                    protection_error = 1'b0;
                    translated_addr = 16'h0000;
                    physical_page = 8'h00;
                end
            end else begin
                translation_error = 1'b0;
                protection_error = 1'b0;
                translated_addr = virtual_addr; // Temporary until translation complete
                physical_page = virtual_addr[15:8];
            end
        end
    end
    
    // Output assignments
    assign physical_addr = translated_addr;
    assign page_fault = translation_error;
    assign protection_violation = protection_error;
    assign translation_valid = !translation_error && !protection_error;
    
    // Page table access
    assign pt_addr = page_table_base + {8'h00, page_number};
    assign pt_read = (pt_state == PT_READ);
    
    // Page table walk state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pt_state <= PT_IDLE;
            current_pte <= 8'h00;
            pt_walk_complete <= 1'b0;
        end else begin
            pt_state <= pt_next_state;
            
            case (pt_state)
                PT_DONE: begin
                    current_pte <= pt_data;
                    pt_walk_complete <= 1'b1;
                end
                default: begin
                    pt_walk_complete <= 1'b0;
                end
            endcase
        end
    end
    
    // Page table state machine next state logic
    always @(*) begin
        pt_next_state = pt_state;
        
        case (pt_state)
            PT_IDLE: begin
                if (mmu_enable && !tlb_hit && (mem_read || mem_write)) begin
                    pt_next_state = PT_READ;
                end
            end
            
            PT_READ: begin
                pt_next_state = PT_WAIT;
            end
            
            PT_WAIT: begin
                if (pt_ready) begin
                    pt_next_state = PT_DONE;
                end
            end
            
            PT_DONE: begin
                pt_next_state = PT_IDLE;
            end
        endcase
    end
    
    // TLB management
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tlb_valid <= 4'b0000;
            for (i = 0; i < 4; i = i + 1) begin
                tlb_vpn[i] <= 8'h00;
                tlb_pte[i] <= 8'h00;
            end
        end else if (tlb_flush) begin
            tlb_valid <= 4'b0000;
        end else if (pt_walk_complete && !tlb_hit) begin
            // Update TLB with new translation
            tlb_vpn[tlb_index] <= page_number;
            tlb_pte[tlb_index] <= current_pte;
            tlb_valid[tlb_index] <= 1'b1;
        end
    end
    
endmodule
