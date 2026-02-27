// Build a Java Swing-based Integrated Development Environment (IDE) called `java_ui`.
// The root path is: /Users/rajanpanneerselvam/work/hdl/java_ui
// It should support the development, simulation, disassembly, and inspection of programs written in C, Java, custom Assembly, and Verilog.
// The IDE will load files from this folder: /Users/rajanpanneerselvam/work/hdl/test_programs

// ----------------------------------------------------------------------------------
// Global Layout
// ----------------------------------------------------------------------------------
// The main frame should contain:
// 1. A JMenuBar at the top, with File > Open option that uses JFileChooser to select a file from the test_programs folder.
//    - Filter for .c, .java, .asm, .hex, .v, .vvp, .log
// 2. A JTabbedPane that contains the following static tabs:
//    [C Tab, Java Tab, Assembly Tab, Hex Tab, Simulation Tab, Simulation Log Tab, Terminal Tab, VCD Tab]
// 3. Based on the selected file type, enable or disable tabs accordingly.
// 4. Maintain a central state that tracks the selected file, type, and compiled/generated intermediate files.
// 5. Each long-running action (compiling, simulating, etc.) should run in a separate thread and update the UI using SwingUtilities.invokeLater().

// ----------------------------------------------------------------------------------
// Tab 1: C Tab
// ----------------------------------------------------------------------------------
// - Enabled only if the selected file is a .c file.
// - Contains:
//   - A JTextArea for viewing/editing the C source code.
//   - A JButton labeled "Compile" which runs a custom C-to-Assembly compiler via Runtime.exec().
//   - A JTextArea below for displaying the compilation log (both stdout and stderr).
// - When compilation is successful:
//   - Store the generated assembly file.
//   - Populate the Assembly Tab with that assembly code.
//   - Enable the Assembly and Hex tabs if not already.

// ----------------------------------------------------------------------------------
// Tab 2: Java Tab
// ----------------------------------------------------------------------------------
// - Enabled only if the selected file is a .java file.
// - Contains:
//   - A JTextArea for Java code.
//   - A JButton labeled "Compile" that invokes `javac`.
//   - A JTextArea to display compilation logs.
//   - A second JTextArea to show bytecode using `javap -c` or ASM bytecode lib.
//   - A third JTextArea to show bytecode explanation, parsed using your custom decoder or integrated local LLM.
// - Must support tab-like layout within this Java Tab:
//   [Source Code] [Bytecode] [Explanation]

// ----------------------------------------------------------------------------------
// Tab 3: Assembly Tab
// ----------------------------------------------------------------------------------
// - Enabled for .c (compiled assembly) or .asm files.
// - Contains:
//   - JTextArea for assembly source.
//   - JButton "Assemble" to run your custom assembler.
//   - JTextArea for assembler logs.
//   - JTextArea or grid/table for assembly instruction explanation.
//     (can use pattern matching or a local LLM to explain opcodes and flow).
// - Outputs compiled hex for the Hex Tab.

// ----------------------------------------------------------------------------------
// Tab 4: Hex Tab
// ----------------------------------------------------------------------------------
// - Always visible.
// - Contains:
//   - A JTextArea showing raw .hex content.
//   - A JTable that disassembles the hex into:
//     Columns: Address | Opcode | RD | RS1 | RS2 | IMM | Mnemonic | Comment
//   - A JButton "Explain Opcodes" which disassembles and uses LLM or rules to show explanations.
//   - Optional: Use your assembler’s disassembler module to decode .hex to .asm automatically.

// ----------------------------------------------------------------------------------
// Tab 5: Simulation Tab
// ----------------------------------------------------------------------------------
// - Contains three inner tabs:
//   [V File] - show Verilog source
//   [VVP File] - show compiled VVP file
//   [Simulate]
// - Simulate tab contains:
//   - A JButton "Simulate" that runs `vvp` and streams output to JTextArea.
//   - A live UART output stream (reading from UART output file).
//   - A JTable to show all CPU registers (R0-R31) updated per simulation cycle.
//   - Memory access buttons (to dump or watch a specific range).
// - Use separate threads for simulation and update UI live.
// - Display cycle count, PC, current instruction if possible.

// ----------------------------------------------------------------------------------
// Tab 6: Simulation Log Tab
// ----------------------------------------------------------------------------------
// - Always visible.
// - Contains:
//   - JTextArea showing complete simulation logs.
//   - Buttons: "Reload", "Clear", "Pause Auto Scroll".

// ----------------------------------------------------------------------------------
// Tab 7: Terminal Tab
// ----------------------------------------------------------------------------------
// - Contains:
//   - A Framebuffer Viewer panel (use a Canvas or JPanel).
//     - Load from framebuffer.bin.
//     - Pixel grid display (grayscale or RGB).
//     - Zoom/scaling support.
//   - A Text Console Viewer:
//     - Read from UART text stream.
//     - Scrollable JTextArea showing text output from CPU.
//     - Input field to simulate keyboard input (optional).

// ----------------------------------------------------------------------------------
// Tab 8: VCD Tab
// ----------------------------------------------------------------------------------
// - Contains:
//   - JFileChooser to load a .vcd file.
//   - Memory Viewer Table:
//     - Allows viewing memory contents at different simulation time steps.
//     - Use JTable or similar.
//   - Basic VCD signal viewer:
//     - Can be timeline/table view for key signals.
//     - Show PC, R0–R31, flags over time.
//   - Filter/search field to find signals.

// ----------------------------------------------------------------------------------
// Global Functionalities
// ----------------------------------------------------------------------------------
// - File watcher that reloads output files (hex, logs, framebuffer, UART) on change.
// - Thread-safe background task handling (compile, run, parse).
// - Color-coded logs: stdout (black), stderr (red).
// - Store last opened file, window size, etc. in config.
// - Status bar at the bottom of main frame:
//   - Shows current mode (Idle/Compiling/Simulating), selected file name, cursor position.
// - Keyboard shortcuts: Ctrl+S (save), Ctrl+R (run sim), Ctrl+Tab (next tab), Ctrl+1..8 (switch tabs)
// - All file paths and subprocesses must use absolute paths (no assumptions).
// - Errors must show popup dialogs if compilation or simulation fails.
// - Modular structure: each tab in its own class, with consistent interface.
// - Tab enabling/disabling logic should respond dynamically to file selection.
// - Set fonts, padding, spacing for legibility. Use JSplitPane and JScrollPane wisely.
