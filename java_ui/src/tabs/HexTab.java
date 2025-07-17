package tabs;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.TableColumnModel;
import java.awt.*;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Clipboard;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.*;
import java.util.Map;
import java.util.HashMap;
import javax.swing.SwingWorker;
import util.AppState;
import util.InstructionDecoder;
import main.CpuIDE;

public class HexTab extends BaseTab {
    private DefaultTableModel tableModel;
    private JTable disassemblyTable;
    private JTextArea explanationArea;
    private JButton explainButton;
    private JButton loadAndTestButton;
    private JButton copySelectionButton;
    private JButton copyAllButton;
    private JLabel filePathLabel;
    private JSplitPane mainSplitPane;
    private JSplitPane rightSplitPane;
    
    // Label storage and management
    private Map<Integer, String> labels = new HashMap<>();
    private JTextArea labelsArea;
    
    public HexTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Enhanced disassembly table with Hex, Binary, and Label columns
        String[] columnNames = {"Address", "Hex", "Binary", "Opcode", "RD", "RS1", "RS2", "IMM", "Mnemonic", "Comment", "Label"};
        tableModel = new DefaultTableModel(columnNames, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false; // Make table read-only
            }
        };
        disassemblyTable = new JTable(tableModel);
        disassemblyTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        disassemblyTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        // Setup column widths for enhanced table
        TableColumnModel disColumnModel = disassemblyTable.getColumnModel();
        disColumnModel.getColumn(0).setPreferredWidth(80);  // Address
        disColumnModel.getColumn(1).setPreferredWidth(80);  // Hex
        disColumnModel.getColumn(2).setPreferredWidth(200); // Binary
        disColumnModel.getColumn(3).setPreferredWidth(60);  // Opcode
        disColumnModel.getColumn(4).setPreferredWidth(40);  // RD
        disColumnModel.getColumn(5).setPreferredWidth(40);  // RS1
        disColumnModel.getColumn(6).setPreferredWidth(40);  // RS2
        disColumnModel.getColumn(7).setPreferredWidth(50);  // IMM
        disColumnModel.getColumn(8).setPreferredWidth(80);  // Mnemonic
        disColumnModel.getColumn(9).setPreferredWidth(150); // Comment
        disColumnModel.getColumn(10).setPreferredWidth(80); // Label
        
        // Add copy functionality with right-click menu
        setupCopyFunctionality();
        
        // Labels display area
        labelsArea = new JTextArea();
        labelsArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        labelsArea.setEditable(false);
        labelsArea.setBackground(new Color(250, 250, 250));
        labelsArea.setText("No labels loaded");
        
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
        
        copySelectionButton = new JButton("Copy Selected");
        copySelectionButton.addActionListener(_ -> copySelectedInstructions());
        
        copyAllButton = new JButton("Copy All");
        copyAllButton.addActionListener(_ -> copyAllInstructions());
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

        // Left panel: disassembly table with buttons
        JPanel leftPanel = new JPanel(new BorderLayout());
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(explainButton);
        buttonPanel.add(copySelectionButton);
        buttonPanel.add(copyAllButton);
        leftPanel.add(new JLabel("Disassembled Instructions:"), BorderLayout.NORTH);
        leftPanel.add(new JScrollPane(disassemblyTable), BorderLayout.CENTER);
        leftPanel.add(buttonPanel, BorderLayout.SOUTH);
        
        // Right panel: split between labels and explanation
        rightSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        
        JPanel labelsPanel = new JPanel(new BorderLayout());
        labelsPanel.add(new JLabel("Labels:"), BorderLayout.NORTH);
        labelsPanel.add(new JScrollPane(labelsArea), BorderLayout.CENTER);
        
        JPanel explanationPanel = new JPanel(new BorderLayout());
        explanationPanel.add(new JLabel("Opcode Explanations:"), BorderLayout.NORTH);
        explanationPanel.add(new JScrollPane(explanationArea), BorderLayout.CENTER);
        
        rightSplitPane.setLeftComponent(labelsPanel);
        rightSplitPane.setRightComponent(explanationPanel);
        rightSplitPane.setDividerLocation(250);
        
        // Main split pane
        mainSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, rightSplitPane);
        mainSplitPane.setDividerLocation(600);
        mainSplitPane.setResizeWeight(0.7);
        
        add(mainSplitPane, BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        // Clear previous data
        tableModel.setRowCount(0);
        labels.clear();
        
        boolean isAssemblerListing = false;
        
        // Parse content - check if it includes assembler listing with labels
        if (content.contains("Labels:") && content.contains("Address  | Machine Code")) {
            loadFromAssemblerListing(content);
            isAssemblerListing = true;
        } else {
            // Load as pure hex content
            loadHexContent(content);
        }
        
        explanationArea.setText("");
        explainButton.setEnabled(false);
        updateFilePath();
        
        // Auto-disassemble if content is available and not already processed as assembler listing
        if (!content.trim().isEmpty() && !isAssemblerListing) {
            disassembleHex();
        }
    }
    
    public void loadFromAssemblerListing(String listing) {
        String[] sections = listing.split("Labels:");
        if (sections.length >= 2) {
            // Parse labels section
            parseLabels(sections[1]);
            
            // Parse instruction section
            String instructionSection = sections[0];
            String[] lines = instructionSection.split("\n");
            
            boolean inInstructionTable = false;
            for (String line : lines) {
                if (line.contains("Address  | Machine Code")) {
                    inInstructionTable = true;
                    continue;
                }
                if (line.contains("---------|")) {
                    continue;
                }
                if (!inInstructionTable) continue;
                
                line = line.trim();
                if (line.isEmpty()) continue;
                
                // Parse line: "00008000 | 48480000     | LOADI R9, #0"
                String[] parts = line.split("\\|");
                if (parts.length >= 2) {
                    String address = parts[0].trim();
                    String hex = parts[1].trim();
                    
                    if (address.length() == 8 && hex.length() >= 8) {
                        String hexValue = hex.substring(0, 8);
                        int instruction = (int) Long.parseLong(hexValue, 16);
                        int addr = Integer.parseInt(address, 16);
                        
                        // Use InstructionDecoder to get full instruction details
                        Object[] decodedRow = InstructionDecoder.decodeInstruction(addr, instruction);
                        
                        // Create enhanced row with Hex and Binary at the beginning
                        Object[] enhancedRow = new Object[11]; // Address, Hex, Binary, Opcode, RD, RS1, RS2, IMM, Mnemonic, Comment, Label
                        enhancedRow[0] = "0x" + address; // Address
                        enhancedRow[1] = hexValue; // Hex
                        enhancedRow[2] = String.format("%32s", Long.toBinaryString(Long.parseLong(hexValue, 16))).replace(' ', '0'); // Binary
                        
                        // Copy decoded instruction data (skip address since we already have it)
                        System.arraycopy(decodedRow, 1, enhancedRow, 3, decodedRow.length - 1);
                        
                        // Add label
                        enhancedRow[10] = labels.getOrDefault(addr, "");
                        
                        tableModel.addRow(enhancedRow);
                    }
                }
            }
        }
        updateLabelsDisplay();
    }
    
    private void loadHexContent(String content) {
        String[] lines = content.split("\n");
        int address = 0x8000; // Default starting address
        
        for (String line : lines) {
            String hex = line.trim();
            if (!hex.isEmpty() && hex.length() >= 8) {
                String hexVal = hex.substring(0, 8);
                int instruction = (int) Long.parseLong(hexVal, 16);
                
                // Use InstructionDecoder to get full instruction details
                Object[] decodedRow = InstructionDecoder.decodeInstruction(address, instruction);
                
                // Create enhanced row with Hex and Binary
                Object[] enhancedRow = new Object[11]; // Address, Hex, Binary, Opcode, RD, RS1, RS2, IMM, Mnemonic, Comment, Label
                enhancedRow[0] = decodedRow[0]; // Address
                enhancedRow[1] = hexVal.toUpperCase(); // Hex
                enhancedRow[2] = String.format("%32s", Long.toBinaryString(Long.parseLong(hexVal, 16))).replace(' ', '0'); // Binary
                
                // Copy decoded instruction data (skip address)
                System.arraycopy(decodedRow, 1, enhancedRow, 3, decodedRow.length - 1);
                
                // Add label
                enhancedRow[10] = labels.getOrDefault(address, "");
                
                tableModel.addRow(enhancedRow);
                address += 4;
            }
        }
    }
    
    private void parseLabels(String labelSection) {
        String[] lines = labelSection.split("\n");
        for (String line : lines) {
            line = line.trim();
            if (line.isEmpty()) continue;
            
            // Parse line: "main                 = 0x00008000"
            String[] parts = line.split("=");
            if (parts.length == 2) {
                String labelName = parts[0].trim();
                String addressStr = parts[1].trim().replace("0x", "").split("\\s+")[0];
                try {
                    int address = Integer.parseInt(addressStr, 16);
                    labels.put(address, labelName);
                } catch (NumberFormatException e) {
                    // Skip invalid addresses
                }
            }
        }
    }
    
    private void updateLabelsDisplay() {
        StringBuilder sb = new StringBuilder();
        if (labels.isEmpty()) {
            sb.append("No labels found");
        } else {
            sb.append("Found ").append(labels.size()).append(" labels:\n\n");
            labels.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> sb.append(String.format("%-20s = 0x%08X\n", entry.getValue(), entry.getKey())));
        }
        labelsArea.setText(sb.toString());
    }
    
    private void setupCopyFunctionality() {
        // Add right-click context menu for copying
        JPopupMenu popupMenu = new JPopupMenu();
        
        JMenuItem copyItem = new JMenuItem("Copy Selected Rows");
        copyItem.addActionListener(_ -> copySelectedInstructions());
        popupMenu.add(copyItem);
        
        JMenuItem copyAllItem = new JMenuItem("Copy All Rows");
        copyAllItem.addActionListener(_ -> copyAllInstructions());
        popupMenu.add(copyAllItem);
        
        // Add popup to disassembly table
        disassemblyTable.setComponentPopupMenu(popupMenu);
        
        // Mouse listener for double-click to copy
        disassemblyTable.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (e.getClickCount() == 2) {
                    copySelectedInstructions();
                }
            }
        });
    }
    
    private void copySelectedInstructions() {
        int[] selectedRows = disassemblyTable.getSelectedRows();
        if (selectedRows.length == 0) {
            updateStatus("No rows selected for copying");
            return;
        }
        
        StringBuilder sb = new StringBuilder();
        sb.append("Selected Instructions (").append(selectedRows.length).append(" rows):\n");
        sb.append("Address      Hex       Binary                            Opcode RD  RS1 RS2 IMM   Mnemonic   Comment                 Label\n");
        sb.append("--------------------------------------------------------------------------------------------------------------------\n");
        
        for (int row : selectedRows) {
            Object[] rowData = new Object[tableModel.getColumnCount()];
            for (int i = 0; i < tableModel.getColumnCount(); i++) {
                rowData[i] = tableModel.getValueAt(row, i);
            }
            
            sb.append(String.format("%-12s %-8s %-32s %-6s %-3s %-3s %-3s %-5s %-10s %-22s %s\n", 
                rowData[0] != null ? rowData[0].toString() : "",  // Address
                rowData[1] != null ? rowData[1].toString() : "",  // Hex
                rowData[2] != null ? rowData[2].toString() : "",  // Binary
                rowData[3] != null ? rowData[3].toString() : "",  // Opcode
                rowData[4] != null ? rowData[4].toString() : "",  // RD
                rowData[5] != null ? rowData[5].toString() : "",  // RS1
                rowData[6] != null ? rowData[6].toString() : "",  // RS2
                rowData[7] != null ? rowData[7].toString() : "",  // IMM
                rowData[8] != null ? rowData[8].toString() : "",  // Mnemonic
                rowData[9] != null ? rowData[9].toString() : "",  // Comment
                rowData[10] != null ? rowData[10].toString() : "" // Label
            ));
        }
        
        copyToClipboard(sb.toString());
        updateStatus("Copied " + selectedRows.length + " instruction(s) to clipboard");
    }
    
    private void copyAllInstructions() {
        StringBuilder sb = new StringBuilder();
        sb.append("All Instructions (").append(tableModel.getRowCount()).append(" rows):\n");
        sb.append("Address      Hex       Binary                            Opcode RD  RS1 RS2 IMM   Mnemonic   Comment                 Label\n");
        sb.append("--------------------------------------------------------------------------------------------------------------------\n");
        
        for (int i = 0; i < tableModel.getRowCount(); i++) {
            Object[] rowData = new Object[tableModel.getColumnCount()];
            for (int j = 0; j < tableModel.getColumnCount(); j++) {
                rowData[j] = tableModel.getValueAt(i, j);
            }
            
            sb.append(String.format("%-12s %-8s %-32s %-6s %-3s %-3s %-3s %-5s %-10s %-22s %s\n",
                rowData[0] != null ? rowData[0].toString() : "",  // Address
                rowData[1] != null ? rowData[1].toString() : "",  // Hex
                rowData[2] != null ? rowData[2].toString() : "",  // Binary
                rowData[3] != null ? rowData[3].toString() : "",  // Opcode
                rowData[4] != null ? rowData[4].toString() : "",  // RD
                rowData[5] != null ? rowData[5].toString() : "",  // RS1
                rowData[6] != null ? rowData[6].toString() : "",  // RS2
                rowData[7] != null ? rowData[7].toString() : "",  // IMM
                rowData[8] != null ? rowData[8].toString() : "",  // Mnemonic
                rowData[9] != null ? rowData[9].toString() : "",  // Comment
                rowData[10] != null ? rowData[10].toString() : "" // Label
            ));
        }
        
        // Add labels if available
        if (!labels.isEmpty()) {
            sb.append("\nLabels:\n");
            sb.append("--------------------\n");
            labels.entrySet().stream()
                .sorted(Map.Entry.comparingByKey())
                .forEach(entry -> sb.append(String.format("%-20s = 0x%08X\n", entry.getValue(), entry.getKey())));
        }
        
        copyToClipboard(sb.toString());
        updateStatus("Copied all " + tableModel.getRowCount() + " instruction(s) to clipboard");
    }
    
    private void copyToClipboard(String text) {
        try {
            StringSelection selection = new StringSelection(text);
            Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
            clipboard.setContents(selection, null);
        } catch (Exception e) {
            showError("Copy Error", "Failed to copy to clipboard: " + e.getMessage());
        }
    }
    
    @Override
    public void saveContent() {
        // Save hex content from the disassembly table
        if (appState.getCurrentFile() != null) {
            try (FileWriter writer = new FileWriter(appState.getCurrentFile())) {
                for (int i = 0; i < tableModel.getRowCount(); i++) {
                    Object hexVal = tableModel.getValueAt(i, 1); // Hex is column 1
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
        for (int i = 0; i < tableModel.getRowCount(); i++) {
            Object hexVal = tableModel.getValueAt(i, 1); // Hex is now column 1 in disassembly table
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
                            
                            // Create enhanced row with Hex and Binary
                            Object[] enhancedRow = new Object[11]; // Address, Hex, Binary, Opcode, RD, RS1, RS2, IMM, Mnemonic, Comment, Label
                            enhancedRow[0] = row[0]; // Address
                            enhancedRow[1] = hexInstr.toUpperCase(); // Hex
                            enhancedRow[2] = String.format("%32s", Long.toBinaryString(Long.parseLong(hexInstr, 16))).replace(' ', '0'); // Binary
                            
                            // Copy decoded instruction data (skip address)
                            System.arraycopy(row, 1, enhancedRow, 3, row.length - 1);
                            
                            // Add label information
                            enhancedRow[10] = labels.getOrDefault(address, "");
                            
                            publish(enhancedRow);
                            
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
            // showInfo("No Instructions", "No instructions to explain. Hex is automatically decoded.");
            updateStatus("No instructions to explain. Hex is automatically decoded.");
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
        if (tableModel != null) tableModel.setRowCount(0);
        if (explanationArea != null) explanationArea.setText("");
        if (labelsArea != null) labelsArea.setText("No labels loaded");
        if (explainButton != null) explainButton.setEnabled(false);
        if (filePathLabel != null) filePathLabel.setText("No hex file loaded");
        labels.clear();
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
        if (tableModel.getRowCount() == 0) {
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
                    // showInfo("Load and Test Hex", 
                    //     "Testbench successfully generated!\n\n" +
                    //     "File: " + verilogFile.getAbsolutePath() + "\n" +
                    //     "Test name: " + testName + "\n\n" +
                    //     "The testbench has been loaded into the V/VVP tab.\n" +
                    //     "You can now generate the VVP file for simulation.");
                    updateStatus("Testbench successfully generated! File: " + verilogFile.getAbsolutePath() + ", Test name: " + testName + ". Loaded into V/VVP tab.");
                    
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
