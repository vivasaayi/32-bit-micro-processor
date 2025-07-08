package tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import util.AppState;

/**
 * Testbench Template Tab for editing testbench templates
 */
public class TestbenchTemplateTab extends BaseTab {
    private JTextArea templateArea;
    private JButton saveTemplateButton;
    private JButton loadTemplateButton;
    private JButton resetToDefaultButton;
    private JLabel templatePathLabel;
    private String currentTemplatePath;
    
    public TestbenchTemplateTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Template editor area
        templateArea = new JTextArea();
        templateArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        templateArea.setEditable(true);
        templateArea.setBackground(new Color(248, 255, 248));
        templateArea.setTabSize(4);
        
        // Buttons
        saveTemplateButton = new JButton("Save Template");
        saveTemplateButton.addActionListener(e -> saveTemplate());
        
        loadTemplateButton = new JButton("Load Template");
        loadTemplateButton.addActionListener(e -> loadTemplate());
        
        resetToDefaultButton = new JButton("Reset to Default");
        resetToDefaultButton.addActionListener(e -> loadDefaultTemplate());
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // Top panel with file info and buttons
        JPanel topPanel = new JPanel(new BorderLayout());
        
        templatePathLabel = new JLabel("Default testbench template");
        templatePathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        templatePathLabel.setForeground(Color.BLUE);
        templatePathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        templatePathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openTemplateLocation();
            }
        });
        
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.add(loadTemplateButton);
        buttonPanel.add(saveTemplateButton);
        buttonPanel.add(resetToDefaultButton);
        
        topPanel.add(templatePathLabel, BorderLayout.WEST);
        topPanel.add(buttonPanel, BorderLayout.EAST);
        
        add(topPanel, BorderLayout.NORTH);
        add(new JScrollPane(templateArea), BorderLayout.CENTER);
        
        // Add instructions at the bottom
        JTextArea instructionsArea = new JTextArea(3, 0);
        instructionsArea.setEditable(false);
        instructionsArea.setBackground(getBackground());
        instructionsArea.setText(
            "Instructions: Edit the testbench template above. Use {HEX_FILE_PATH} as placeholder for hex file path.\n" +
            "Use {TEST_NAME} as placeholder for test name. The template will be used when 'Load and Test Hex' is clicked.\n" +
            "Save your custom template or reset to default template as needed."
        );
        instructionsArea.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        instructionsArea.setForeground(Color.GRAY);
        
        add(new JScrollPane(instructionsArea), BorderLayout.SOUTH);
        
        // Initialize with default template after layout is complete
        loadDefaultTemplate();
    }
    
    @Override
    public void loadContent(String content) {
        templateArea.setText(content);
    }
    
    private void loadDefaultTemplate() {
        String defaultTemplate = "`timescale 1ns / 1ps\n" +
            "\n" +
            "module tb_{TEST_NAME};\n" +
            "    reg clk;\n" +
            "    reg rst_n;\n" +
            "    wire [31:0] debug_pc;\n" +
            "    wire [31:0] debug_instruction;\n" +
            "    wire [31:0] debug_reg_data;\n" +
            "    wire [4:0] debug_reg_addr;\n" +
            "    wire [31:0] debug_result;\n" +
            "    wire debug_halted;\n" +
            "\n" +
            "    // Framebuffer parameters\n" +
            "    parameter FB_WIDTH = 320;\n" +
            "    parameter FB_HEIGHT = 240;\n" +
            "    parameter FB_BASE_ADDR = 32'h800;\n" +
            "    parameter FB_SIZE = FB_WIDTH * FB_HEIGHT * 4;\n" +
            "    parameter DUMP_INTERVAL = 100;\n" +
            "\n" +
            "    integer cycle_count = 0;\n" +
            "    integer dump_count = 0;\n" +
            "    integer fb_dump_file;\n" +
            "    integer last_dump_cycle = 0;\n" +
            "    integer graphics_pixels = 0;\n" +
            "    reg fb_dump_enable = 1;\n" +
            "\n" +
            "    // Clock generation\n" +
            "    initial begin\n" +
            "        clk = 0;\n" +
            "        forever #5 clk = ~clk;\n" +
            "    end\n" +
            "\n" +
            "    always @(posedge clk) begin\n" +
            "        cycle_count = cycle_count + 1;\n" +
            "        if (fb_dump_enable && (cycle_count - last_dump_cycle) >= DUMP_INTERVAL) begin\n" +
            "            dump_framebuffer();\n" +
            "            last_dump_cycle = cycle_count;\n" +
            "        end\n" +
            "    end\n" +
            "\n" +
            "    // Framebuffer dump task\n" +
            "    task dump_framebuffer;\n" +
            "        integer x, y, pixel_addr, pixel_data;\n" +
            "        integer r, g, b;\n" +
            "        begin\n" +
            "            $display(\"Dumping framebuffer at cycle %d...\", cycle_count);\n" +
            "            fb_dump_file = $fopen(\"temp/reports/framebuffer.ppm\", \"w\");\n" +
            "            if (fb_dump_file != 0) begin\n" +
            "                $fwrite(fb_dump_file, \"P6\\n\");\n" +
            "                $fwrite(fb_dump_file, \"# RISC CPU Framebuffer\\n\");\n" +
            "                $fwrite(fb_dump_file, \"%d %d\\n\", FB_WIDTH, FB_HEIGHT);\n" +
            "                $fwrite(fb_dump_file, \"255\\n\");\n" +
            "                for (y = 0; y < FB_HEIGHT; y = y + 1) begin\n" +
            "                    for (x = 0; x < FB_WIDTH; x = x + 1) begin\n" +
            "                        pixel_addr = (FB_BASE_ADDR/4) + (y * FB_WIDTH + x);\n" +
            "                        pixel_data = uut.internal_memory[pixel_addr];\n" +
            "                        r = (pixel_data >> 24) & 8'hFF;\n" +
            "                        g = (pixel_data >> 16) & 8'hFF;\n" +
            "                        b = (pixel_data >> 8) & 8'hFF;\n" +
            "                        $fwrite(fb_dump_file, \"%c%c%c\", r, g, b);\n" +
            "                    end\n" +
            "                end\n" +
            "                $fclose(fb_dump_file);\n" +
            "                dump_count = dump_count + 1;\n" +
            "                $display(\"Framebuffer dump #%d complete\", dump_count);\n" +
            "            end\n" +
            "        end\n" +
            "    endtask\n" +
            "\n" +
            "    // Log memory dump task\n" +
            "    task dump_log_memory;\n" +
            "        integer i, log_length, log_addr;\n" +
            "        reg [7:0] log_char;\n" +
            "        begin\n" +
            "            log_length = uut.internal_memory[4096];\n" +
            "            $display(\"=== LOG OUTPUT ===\");\n" +
            "            if (log_length > 0 && log_length < 1024) begin\n" +
            "                $write(\"Log: \");\n" +
            "                for (i = 0; i < log_length; i = i + 1) begin\n" +
            "                    log_addr = 3072 + (i / 4);\n" +
            "                    case (i % 4)\n" +
            "                        0: log_char = uut.internal_memory[log_addr][7:0];\n" +
            "                        1: log_char = uut.internal_memory[log_addr][15:8];\n" +
            "                        2: log_char = uut.internal_memory[log_addr][23:16];\n" +
            "                        3: log_char = uut.internal_memory[log_addr][31:24];\n" +
            "                    endcase\n" +
            "                    if (log_char >= 32 && log_char <= 126) $write(\"%c\", log_char);\n" +
            "                    else if (log_char == 10) $write(\"\\n\");\n" +
            "                end\n" +
            "                $display(\"\");\n" +
            "            end\n" +
            "            $display(\"=== END LOG ===\");\n" +
            "        end\n" +
            "    endtask\n" +
            "\n" +
            "    // Reset and test\n" +
            "    initial begin\n" +
            "        $dumpfile(\"/Users/rajanpanneerselvam/work/hdl/temp/{TEST_NAME}.vcd\");\n" +
            "        $dumpvars(0, tb_{TEST_NAME});\n" +
            "        $readmemh(\"{HEX_FILE_PATH}\", uut.internal_memory, 8192);\n" +
            "        rst_n = 0;\n" +
            "        #20;\n" +
            "        rst_n = 1;\n" +
            "        #1000;\n" +
            "        dump_framebuffer();\n" +
            "        #200000;\n" +
            "        dump_framebuffer();\n" +
            "        dump_log_memory();\n" +
            "        $finish;\n" +
            "    end\n" +
            "\n" +
            "    // Instantiate the microprocessor system\n" +
            "    microprocessor_system uut (\n" +
            "        .clk(clk),\n" +
            "        .rst_n(rst_n),\n" +
            "        .ext_addr(),\n" +
            "        .ext_data(),\n" +
            "        .ext_mem_read(),\n" +
            "        .ext_mem_write(),\n" +
            "        .ext_mem_enable(),\n" +
            "        .ext_mem_ready(1'b1),\n" +
            "        .io_addr(),\n" +
            "        .io_data(),\n" +
            "        .io_read(),\n" +
            "        .io_write(),\n" +
            "        .external_interrupts(8'b0),\n" +
            "        .system_halted(),\n" +
            "        .pc_out(debug_pc),\n" +
            "        .cpu_flags(),\n" +
            "        .debug_pc(debug_pc),\n" +
            "        .debug_instruction(debug_instruction),\n" +
            "        .debug_reg_data(debug_reg_data),\n" +
            "        .debug_reg_addr(debug_reg_addr),\n" +
            "        .debug_result(debug_result),\n" +
            "        .debug_halted(debug_halted)\n" +
            "    );\n" +
            "endmodule\n";
        templateArea.setText(defaultTemplate);
        templatePathLabel.setText("Default testbench template");
        currentTemplatePath = null;
        updateStatus("Default testbench template loaded");
    }
    
    private void saveTemplate() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setCurrentDirectory(new File("/Users/rajanpanneerselvam/work/hdl/templates"));
        fileChooser.setSelectedFile(new File("testbench_template.v"));
        
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = fileChooser.getSelectedFile();
            try (FileWriter writer = new FileWriter(file)) {
                writer.write(templateArea.getText());
                currentTemplatePath = file.getAbsolutePath();
                templatePathLabel.setText("Template: " + file.getName());
                updateStatus("Template saved: " + file.getName());
                showInfo("Save Template", "Testbench template saved successfully to:\n" + file.getAbsolutePath());
            } catch (Exception e) {
                showError("Save Template", "Error saving template: " + e.getMessage());
            }
        }
    }
    
    private void loadTemplate() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setCurrentDirectory(new File("/Users/rajanpanneerselvam/work/hdl/templates"));
        
        if (fileChooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = fileChooser.getSelectedFile();
            try {
                String content = new String(java.nio.file.Files.readAllBytes(file.toPath()));
                templateArea.setText(content);
                currentTemplatePath = file.getAbsolutePath();
                templatePathLabel.setText("Template: " + file.getName());
                updateStatus("Template loaded: " + file.getName());
            } catch (Exception e) {
                showError("Load Template", "Error loading template: " + e.getMessage());
            }
        }
    }
    
    private void openTemplateLocation() {
        if (currentTemplatePath != null) {
            try {
                File file = new File(currentTemplatePath);
                if (file.exists()) {
                    // Open file location in Finder (macOS)
                    if (System.getProperty("os.name").toLowerCase().contains("mac")) {
                        Runtime.getRuntime().exec(new String[]{"open", "-R", file.getAbsolutePath()});
                    } else if (System.getProperty("os.name").toLowerCase().contains("windows")) {
                        Runtime.getRuntime().exec(new String[]{"explorer", "/select,", file.getAbsolutePath()});
                    } else {
                        // Linux - open containing directory
                        Runtime.getRuntime().exec(new String[]{"xdg-open", file.getParent()});
                    }
                }
            } catch (Exception e) {
                updateStatus("Error opening template location: " + e.getMessage());
            }
        }
    }
    
    public String getTemplateContent() {
        return templateArea.getText();
    }
    
    public String generateTestbench(String testName, String hexFilePath) {
        String template = templateArea.getText();
        
        // Replace placeholders
        template = template.replace("{TEST_NAME}", testName);
        template = template.replace("{HEX_FILE_PATH}", hexFilePath);
        
        return template;
    }
    
    /**
     * Generate testbench with file-based naming from current application state
     */
    public String generateTestbenchFromCurrentFile(AppState appState) {
        if (appState.getCurrentFile() == null) {
            return generateTestbench("default", "path/to/hex/file.hex");
        }
        
        // Generate test name from current file
        String fileName = appState.getCurrentFile().getName();
        String testName = fileName.contains(".") ? 
            fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
            
        // Generate hex file path based on current file
        String hexFilePath;
        File currentFile = appState.getCurrentFile();
        if (appState.hasGeneratedFile("hex")) {
            // Use generated hex file
            hexFilePath = appState.getGeneratedFile("hex").getAbsolutePath();
        } else {
            // Generate expected hex file path
            String baseName = currentFile.getName();
            if (baseName.contains(".")) {
                baseName = baseName.substring(0, baseName.lastIndexOf('.'));
            }
            hexFilePath = new File(currentFile.getParent(), baseName + ".hex").getAbsolutePath();
        }
        
        return generateTestbench(testName, hexFilePath);
    }
    
    @Override
    public void clearContent() {
        loadDefaultTemplate();
    }
    
    @Override
    public void saveContent() {
        saveTemplate();
    }
}
