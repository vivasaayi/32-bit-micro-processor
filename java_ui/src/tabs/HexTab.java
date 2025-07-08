package tabs;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.io.*;
import javax.swing.SwingWorker;
import util.AppState;
import util.InstructionDecoder;
import main.CpuIDE;

public class HexTab extends BaseTab {
    private JTable hexGridTable;
    private DefaultTableModel hexGridTableModel;
    private JTable disassemblyTable;
    private DefaultTableModel tableModel;
    private JTextArea explanationArea;
    private JButton explainButton;
    private JButton loadAndTestButton;
    private JLabel filePathLabel;
    private JSplitPane mainSplitPane;
    private JSplitPane rightSplitPane;
    
    public HexTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Hex grid table for Hex and Binary columns
        String[] hexGridColumns = {"Hex", "Binary"};
        hexGridTableModel = new DefaultTableModel(hexGridColumns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        hexGridTable = new JTable(hexGridTableModel);
        hexGridTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        hexGridTable.setRowHeight(20);
        hexGridTable.setBackground(new Color(248, 248, 248));
        
        // Disassembly table
        String[] columnNames = {"Address", "Opcode", "RD", "RS1", "RS2", "IMM", "Mnemonic", "Comment"};
        tableModel = new DefaultTableModel(columnNames, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // Make table read-only
            }
        };
        disassemblyTable = new JTable(tableModel);
        disassemblyTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        disassemblyTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        // Explanation area
        explanationArea = new JTextArea();
        explanationArea.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 12));
        explanationArea.setEditable(false);
        explanationArea.setLineWrap(true);
        explanationArea.setWrapStyleWord(true);
        explanationArea.setBackground(new Color(255, 255, 240));
        
        // Buttons
        explainButton = new JButton("Explain Opcodes");
        explainButton.addActionListener(_ -> explainOpcodes());
        explainButton.setEnabled(false);
        
        loadAndTestButton = new JButton("Load and Test Hex");
        loadAndTestButton.addActionListener(_ -> loadAndTestHex());
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());

        // File path label at the top
        filePathLabel = new JLabel("No hex file loaded");
        filePathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        filePathLabel.setForeground(Color.BLUE);
        filePathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        filePathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openFileLocation();
            }
        });

        // Top panel with file path and Load/Test button
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.add(filePathLabel, BorderLayout.WEST);
        JPanel loadTestPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        loadTestPanel.add(loadAndTestButton);
        topPanel.add(loadTestPanel, BorderLayout.EAST);
        // Add a separator for clarity
        JPanel topWithSeparator = new JPanel(new BorderLayout());
        topWithSeparator.add(topPanel, BorderLayout.NORTH);
        topWithSeparator.add(new JSeparator(), BorderLayout.SOUTH);
        add(topWithSeparator, BorderLayout.NORTH);

        // Left panel: hex content with buttons
        JPanel leftPanel = new JPanel(new BorderLayout());
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(explainButton);
        leftPanel.add(new JLabel("Raw Hex Content (Grid):"), BorderLayout.NORTH);
        leftPanel.add(new JScrollPane(hexGridTable), BorderLayout.CENTER);
        leftPanel.add(buttonPanel, BorderLayout.SOUTH);
        
        // Right panel: table and explanation
        rightSplitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT);
        
        JPanel tablePanel = new JPanel(new BorderLayout());
        tablePanel.add(new JLabel("Disassembled Instructions:"), BorderLayout.NORTH);
        tablePanel.add(new JScrollPane(disassemblyTable), BorderLayout.CENTER);
        
        JPanel explanationPanel = new JPanel(new BorderLayout());
        explanationPanel.add(new JLabel("Opcode Explanations:"), BorderLayout.NORTH);
        explanationPanel.add(new JScrollPane(explanationArea), BorderLayout.CENTER);
        
        rightSplitPane.setTopComponent(tablePanel);
        rightSplitPane.setBottomComponent(explanationPanel);
        rightSplitPane.setDividerLocation(300);
        
        // Main split pane
        mainSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, rightSplitPane);
        mainSplitPane.setDividerLocation(400);
        mainSplitPane.setResizeWeight(0.4);
        
        add(mainSplitPane, BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        // Fill the hex grid table
        hexGridTableModel.setRowCount(0);
        String[] lines = content.split("\n");
        for (String line : lines) {
            String hex = line.trim();
            if (!hex.isEmpty() && hex.length() >= 8) {
                String hexVal = hex.substring(0, 8);
                String binVal = String.format("%32s", Long.toBinaryString(Long.parseLong(hexVal, 16))).replace(' ', '0');
                hexGridTableModel.addRow(new Object[]{hexVal, binVal});
            }
        }
        tableModel.setRowCount(0); // Clear table
        explanationArea.setText("");
        explainButton.setEnabled(false);
        updateFilePath();
        
        // Auto-disassemble if content is available
        if (!content.trim().isEmpty()) {
            disassembleHex();
        }
    }
    
    @Override
    public void saveContent() {
        // Save hex content from the grid
        if (appState.getCurrentFile() != null) {
            try (FileWriter writer = new FileWriter(appState.getCurrentFile())) {
                for (int i = 0; i < hexGridTableModel.getRowCount(); i++) {
                    Object hexVal = hexGridTableModel.getValueAt(i, 0);
                    if (hexVal != null) {
                        writer.write(hexVal.toString() + "\n");
                    }
                }
                updateStatus("Saved: " + appState.getCurrentFile().getName());
            } catch (IOException e) {
                showError("Save Error", "Failed to save file: " + e.getMessage());
            }
        }
    }

    private String getHexContentFromGrid() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < hexGridTableModel.getRowCount(); i++) {
            Object hexVal = hexGridTableModel.getValueAt(i, 0);
            if (hexVal != null) {
                sb.append(hexVal.toString()).append("\n");
            }
        }
        return sb.toString();
    }

    public void loadFromAssembly(String hexContent) {
        // Called when assembly is assembled to hex
        loadContent(hexContent);
        updateStatus("Hex loaded from assembly");
        // Auto-disassemble if content is available
        if (!hexContent.trim().isEmpty()) {
            disassembleHex();
        }
    }
    
    private void disassembleHex() {
        String hexContent = getHexContentFromGrid().trim();
        if (hexContent.isEmpty()) {
            showError("Disassemble Error", "No hex content to disassemble");
            return;
        }
        
        updateStatus("Disassembling hex...");
        
        SwingWorker<Void, Object[]> worker = new SwingWorker<Void, Object[]>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Clear existing table data
                    SwingUtilities.invokeLater(() -> tableModel.setRowCount(0));
                    
                    String[] lines = hexContent.split("\n");
                    int address = 0x8000; // Starting address
                    
                    for (String line : lines) {
                        line = line.trim();
                        if (line.isEmpty() || line.startsWith("//") || line.startsWith("#")) {
                            continue;
                        }
                        
                        // Parse hex instruction (assuming 32-bit words)
                        if (line.length() >= 8) {
                            String hexInstr = line.substring(0, 8);
                            int instruction = (int) Long.parseLong(hexInstr, 16);
                            
                            // Use shared InstructionDecoder
                            Object[] row = InstructionDecoder.decodeInstruction(address, instruction);
                            publish(row);
                            
                            address += 4; // Increment by 4 bytes
                        }
                    }
                    
                } catch (Exception e) {
                    SwingUtilities.invokeLater(() -> 
                        showError("Disassemble Error", "Failed to disassemble: " + e.getMessage()));
                }
                
                return null;
            }
            
            @Override
            protected void process(java.util.List<Object[]> chunks) {
                for (Object[] row : chunks) {
                    tableModel.addRow(row);
                }
            }
            
            @Override
            protected void done() {
                explainButton.setEnabled(true);
                updateStatus("Disassembly complete");
            }
        };
        
        worker.execute();
    }
    
    private void explainOpcodes() {
        if (tableModel.getRowCount() == 0) {
            showInfo("No Instructions", "No instructions to explain. Hex is automatically decoded.");
            return;
        }
        
        explainButton.setEnabled(false);
        updateStatus("Explaining opcodes...");
        
        SwingWorker<String, Void> worker = new SwingWorker<String, Void>() {
            @Override
            protected String doInBackground() throws Exception {
                return generateOpcodeExplanation();
            }
            
            @Override
            protected void done() {
                try {
                    String explanation = get();
                    explanationArea.setText(explanation);
                    updateStatus("Opcode explanation complete");
                } catch (Exception e) {
                    showError("Explanation Error", "Failed to explain opcodes: " + e.getMessage());
                }
                explainButton.setEnabled(true);
            }
        };
        
        worker.execute();
    }
    
    private String generateOpcodeExplanation() {
        StringBuilder explanation = new StringBuilder();
        explanation.append("HEX DISASSEMBLY EXPLANATION\n");
        explanation.append("===========================\n\n");
        
        explanation.append("PROGRAM FLOW ANALYSIS:\n");
        explanation.append("----------------------\n");
        
        for (int i = 0; i < tableModel.getRowCount(); i++) {
            String address = (String) tableModel.getValueAt(i, 0);
            String mnemonic = (String) tableModel.getValueAt(i, 6);
            String comment = (String) tableModel.getValueAt(i, 7);
            
            explanation.append(String.format("%s: %s\n", address, mnemonic));
            explanation.append(String.format("     %s\n", comment));
            
            // Add flow analysis
            if (mnemonic.startsWith("JMP") || mnemonic.startsWith("JZ") || mnemonic.startsWith("JNZ")) {
                explanation.append("     ⚠ Control flow change - potential branch/loop\n");
            } else if (mnemonic.startsWith("HALT")) {
                explanation.append("     ⚠ Program termination point\n");
            } else if (mnemonic.startsWith("LOADI")) {
                explanation.append("     → Initializing register with constant\n");
            } else if (mnemonic.startsWith("STORE") || mnemonic.startsWith("LOAD")) {
                explanation.append("     → Memory access operation\n");
            }
            explanation.append("\n");
        }
        
        explanation.append("\nREGISTER USAGE SUMMARY:\n");
        explanation.append("-----------------------\n");
        // Add register usage analysis
        explanation.append("This analysis shows which registers are used and how.\n");
        explanation.append("Consider register allocation efficiency and data flow.\n\n");
        
        explanation.append("NOTE: This is a basic analysis. For advanced verification,\n");
        explanation.append("consider integrating with a local LLM for deeper insights.\n");
        
        return explanation.toString();
    }
    
    @Override
    public void clearContent() {
        if (hexGridTableModel != null) hexGridTableModel.setRowCount(0);
        if (tableModel != null) tableModel.setRowCount(0);
        if (explanationArea != null) explanationArea.setText("");
        if (explainButton != null) explainButton.setEnabled(false);
        if (filePathLabel != null) filePathLabel.setText("No hex file loaded");
    }
    
    private void openFileLocation() {
        try {
            if (appState.getCurrentFile() != null && appState.getCurrentFile().exists()) {
                File file = appState.getCurrentFile();
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
            updateStatus("Error opening file location: " + e.getMessage());
        }
    }
    
    public void updateFilePath() {
        if (appState.getCurrentFile() != null) {
            filePathLabel.setText("Hex File: " + appState.getCurrentFile().getAbsolutePath());
        } else {
            filePathLabel.setText("No hex file loaded");
        }
    }
    
    private void loadAndTestHex() {
        if (hexGridTableModel.getRowCount() == 0) {
            showError("Load and Test Hex", "No hex content to test. Please load or generate a hex file first.");
            return;
        }
        
        updateStatus("Generating testbench for hex testing...");
        
        try {
            // Get the testbench template tab and vvp tab from parent frame
            if (parentFrame instanceof CpuIDE) {
                CpuIDE ide = (CpuIDE) parentFrame;
                TestbenchTemplateTab templateTab = ide.getTestbenchTemplateTab();
                VVvpTab vvpTab = ide.getVVvpTab();
                
                if (templateTab == null || vvpTab == null) {
                    showError("Load and Test Hex", "Unable to access template or VVP tabs.");
                    return;
                }
                
                // Generate testbench content using current app state
                String testbenchContent = templateTab.generateTestbenchFromCurrentFile(appState);
                
                // Get current file info for naming the generated testbench file
                String testName = "hex_test";
                if (appState.getCurrentFile() != null) {
                    String fileName = appState.getCurrentFile().getName();
                    if (fileName.contains(".")) {
                        testName = fileName.substring(0, fileName.lastIndexOf('.'));
                    }
                }
                
                // Save the generated testbench to a file
                try {
                    File verilogFile = new File("temp", testName + "_testbench.v");
                    verilogFile.getParentFile().mkdirs(); // Ensure temp directory exists
                    
                    try (FileWriter writer = new FileWriter(verilogFile)) {
                        writer.write(testbenchContent);
                    }
                    
                    // Update AppState with the generated verilog file
                    appState.addGeneratedFile("verilog", verilogFile);
                    
                    // Load the testbench content into VVvpTab with file path
                    vvpTab.loadVerilogContent(testbenchContent, verilogFile.getAbsolutePath());
                    
                    // Switch to the V/VVP tab
                    ide.switchToTab("V/VVP");
                    
                    updateStatus("Testbench generated and loaded into V/VVP tab");
                    showInfo("Load and Test Hex", 
                        "Testbench successfully generated!\n\n" +
                        "File: " + verilogFile.getAbsolutePath() + "\n" +
                        "Test name: " + testName + "\n\n" +
                        "The testbench has been loaded into the V/VVP tab.\n" +
                        "You can now generate the VVP file for simulation.");
                    
                } catch (IOException e) {
                    showError("Load and Test Hex", "Failed to save testbench file: " + e.getMessage());
                }
                
            } else {
                showError("Load and Test Hex", "Unable to access IDE components for testbench generation.");
            }
            
        } catch (Exception e) {
            showError("Load and Test Hex", "Error generating testbench: " + e.getMessage());
        }
    }
    
    public DefaultTableModel getDisassemblyTableModel() {
        return tableModel;
    }
    
    public JTable getDisassemblyTable() {
        return disassemblyTable;
    }
    
    // Create a shared disassembly panel that can be used in other tabs
    public JPanel createSharedDisassemblyPanel() {
        JPanel panel = new JPanel(new BorderLayout());
        panel.add(new JLabel("Disassembled Instructions:"), BorderLayout.NORTH);
        panel.add(new JScrollPane(disassemblyTable), BorderLayout.CENTER);
        return panel;
    }
}
