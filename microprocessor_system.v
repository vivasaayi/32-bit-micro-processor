/**
 * Top-level 8-bit Microprocessor System
 * 
 * Integrates all components to create a complete system capable
 * of running a Linux-like operating system.
 * 
 * Components:
 * - CPU Core with MMU
 * - Memory Controller
 * - I/O Peripherals (UART, Timer, Interrupt Controller)
 * - System Bus
 * - Boot ROM
 */

module microprocessor_system (
    input wire clk,
    input wire rst_n,
    
    // External memory interface
    output wire [15:0] ext_mem_addr,
    inout wire [7:0] ext_mem_data,
    output wire ext_mem_read,
    output wire ext_mem_write,
    output wire ext_mem_cs,
    input wire ext_mem_ready,
    
    // UART interface
    input wire uart_rx,
    output wire uart_tx,
    
    // GPIO pins
    inout wire [7:0] gpio_pins,
    
    // System status
    output wire system_halted,
    output wire user_mode_active,
    output wire [7:0] debug_reg
);

    // Internal buses
    wire [15:0] cpu_addr_bus;
    wire [7:0] cpu_data_bus;
    wire cpu_mem_read, cpu_mem_write;
    wire cpu_mem_ready;
    
    // MMU interface
    wire [15:0] virtual_addr, physical_addr;
    wire page_fault, protection_violation;
    wire mmu_enable = 1'b1; // Enable MMU for Linux support
    wire [15:0] page_table_base = 16'hE000; // Page table in kernel space
    
    // I/O bus
    wire [7:0] io_addr;
    wire [7:0] io_data;
    wire io_read, io_write;
    wire io_ready;
    
    // Interrupt signals
    wire [7:0] interrupt_sources;
    wire [7:0] cpu_interrupt_req;
    wire cpu_interrupt_ack;
    wire [2:0] interrupt_vector;
    
    // Peripheral interrupts
    wire uart_interrupt;
    wire timer_interrupt;
    
    // Peripheral chip selects
    wire uart_cs, timer_cs, interrupt_cs, gpio_cs;
    
    // Address decoding for I/O peripherals
    assign uart_cs = (io_addr[7:4] == 4'h0); // 0xF000-0xF00F
    assign timer_cs = (io_addr[7:4] == 4'h1); // 0xF010-0xF01F
    assign interrupt_cs = (io_addr[7:4] == 4'h2); // 0xF020-0xF02F
    assign gpio_cs = (io_addr[7:4] == 4'h3); // 0xF030-0xF03F
    
    // Collect interrupt sources
    assign interrupt_sources = {
        5'b00000,           // Reserved
        timer_interrupt,    // IRQ 2
        uart_interrupt,     // IRQ 1
        1'b0               // IRQ 0 - External
    };
    
    // Instantiate CPU Core
    cpu_core cpu (
        .clk(clk),
        .rst_n(rst_n),
        .addr_bus(cpu_addr_bus),
        .data_bus(cpu_data_bus),
        .mem_read(cpu_mem_read),
        .mem_write(cpu_mem_write),
        .mem_ready(cpu_mem_ready),
        .interrupt_req(cpu_interrupt_req),
        .interrupt_ack(cpu_interrupt_ack),
        .io_addr(io_addr),
        .io_data(io_data),
        .io_read(io_read),
        .io_write(io_write),
        .halted(system_halted),
        .user_mode(user_mode_active)
    );
    
    // Instantiate MMU
    mmu memory_management (
        .clk(clk),
        .rst_n(rst_n),
        .virtual_addr(cpu_addr_bus),
        .physical_addr(physical_addr),
        .mem_read(cpu_mem_read),
        .mem_write(cpu_mem_write),
        .user_mode(user_mode_active),
        .page_fault(page_fault),
        .protection_violation(protection_violation),
        .translation_valid(),
        .page_table_base(page_table_base),
        .mmu_enable(mmu_enable),
        .tlb_flush(1'b0),
        .pt_addr(),
        .pt_data(8'h00),
        .pt_read(),
        .pt_ready(1'b1)
    );
    
    // Instantiate Memory Controller
    memory_controller mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(physical_addr),
        .cpu_data(cpu_data_bus),
        .cpu_read(cpu_mem_read),
        .cpu_write(cpu_mem_write),
        .cpu_ready(cpu_mem_ready),
        .mem_addr(ext_mem_addr),
        .mem_data(ext_mem_data),
        .mem_read(ext_mem_read),
        .mem_write(ext_mem_write),
        .mem_cs(ext_mem_cs),
        .mem_ready(ext_mem_ready),
        .io_addr(io_addr),
        .io_data(io_data),
        .io_read(io_read),
        .io_write(io_write),
        .io_cs(),
        .io_ready(io_ready),
        .cache_enable(),
        .cache_hit(1'b0),
        .cache_ready(1'b1)
    );
    
    // Instantiate UART
    uart system_uart (
        .clk(clk),
        .rst_n(rst_n),
        .addr(io_addr[2:0]),
        .data_in(io_data),
        .data_out(),
        .read(io_read && uart_cs),
        .write(io_write && uart_cs),
        .cs(uart_cs),
        .rx(uart_rx),
        .tx(uart_tx),
        .interrupt(uart_interrupt),
        .baud_div(16'd434) // 9600 baud at 50MHz
    );
    
    // Instantiate Timer
    timer system_timer (
        .clk(clk),
        .rst_n(rst_n),
        .addr(io_addr[2:0]),
        .data_in(io_data),
        .data_out(),
        .read(io_read && timer_cs),
        .write(io_write && timer_cs),
        .cs(timer_cs),
        .interrupt(timer_interrupt)
    );
    
    // Instantiate Interrupt Controller
    interrupt_controller int_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .addr(io_addr[2:0]),
        .data_in(io_data),
        .data_out(),
        .read(io_read && interrupt_cs),
        .write(io_write && interrupt_cs),
        .cs(interrupt_cs),
        .irq_in(interrupt_sources),
        .irq_out(cpu_interrupt_req),
        .irq_vector(interrupt_vector),
        .irq_ack(cpu_interrupt_ack)
    );
    
    // Simple GPIO (placeholder)
    reg [7:0] gpio_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_reg <= 8'h00;
        end else if (io_write && gpio_cs) begin
            gpio_reg <= io_data;
        end
    end
    assign gpio_pins = gpio_reg;
    
    // I/O ready signal (simple implementation)
    assign io_ready = 1'b1; // Always ready for this simple implementation
    
    // Debug register (shows current state)
    assign debug_reg = {
        system_halted,
        user_mode_active,
        page_fault,
        protection_violation,
        uart_interrupt,
        timer_interrupt,
        |cpu_interrupt_req,
        mmu_enable
    };
    
endmodule
