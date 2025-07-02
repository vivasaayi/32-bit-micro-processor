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
        String defaultTemplate = 
            "`timescale 1ns / 1ps\n\n" +
            "module tb_{TEST_NAME};\n\n" +
            "    // Clock and reset signals\n" +
            "    reg clk = 0;\n" +
            "    reg rst = 1;\n" +
            "    \n" +
            "    // CPU interface signals\n" +
            "    wire [31:0] cpu_data_out;\n" +
            "    wire [31:0] cpu_addr;\n" +
            "    wire cpu_we;\n" +
            "    wire cpu_re;\n" +
            "    \n" +
            "    // Memory signals\n" +
            "    wire [31:0] mem_data_out;\n" +
            "    wire mem_ready;\n" +
            "    \n" +
            "    // VCD dump\n" +
            "    initial begin\n" +
            "        $dumpfile(\"temp/c_generated_vcd/{TEST_NAME}.vcd\");\n" +
            "        $dumpvars(0, tb_{TEST_NAME});\n" +
            "    end\n" +
            "    \n" +
            "    // Clock generation\n" +
            "    always #5 clk = ~clk; // 100MHz clock\n" +
            "    \n" +
            "    // Instantiate the microprocessor system\n" +
            "    microprocessor_system uut (\n" +
            "        .clk(clk),\n" +
            "        .rst(rst),\n" +
            "        .cpu_data_out(cpu_data_out),\n" +
            "        .cpu_addr(cpu_addr),\n" +
            "        .cpu_we(cpu_we),\n" +
            "        .cpu_re(cpu_re),\n" +
            "        .mem_data_out(mem_data_out),\n" +
            "        .mem_ready(mem_ready)\n" +
            "    );\n" +
            "    \n" +
            "    // Load hex file into memory\n" +
            "    initial begin\n" +
            "        $readmemh(\"{HEX_FILE_PATH}\", uut.memory_controller.memory_array);\n" +
            "    end\n" +
            "    \n" +
            "    // Test sequence\n" +
            "    initial begin\n" +
            "        // Reset sequence\n" +
            "        #10 rst = 0;\n" +
            "        \n" +
            "        // Run for specified number of cycles\n" +
            "        #10000;\n" +
            "        \n" +
            "        // Display final results\n" +
            "        $display(\"Simulation completed for {TEST_NAME}\");\n" +
            "        $display(\"Final PC: %h\", uut.cpu_core.pc);\n" +
            "        $display(\"Register R1: %h\", uut.cpu_core.register_file.registers[1]);\n" +
            "        $display(\"Register R2: %h\", uut.cpu_core.register_file.registers[2]);\n" +
            "        \n" +
            "        $finish;\n" +
            "    end\n" +
            "    \n" +
            "    // Monitor key signals\n" +
            "    always @(posedge clk) begin\n" +
            "        if (!rst && cpu_we) begin\n" +
            "            $display(\"Time %t: Memory Write - Addr: %h, Data: %h\", $time, cpu_addr, cpu_data_out);\n" +
            "        end\n" +
            "        if (!rst && cpu_re) begin\n" +
            "            $display(\"Time %t: Memory Read - Addr: %h, Data: %h\", $time, cpu_addr, mem_data_out);\n" +
            "        end\n" +
            "    end\n" +
            "    \n" +
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
