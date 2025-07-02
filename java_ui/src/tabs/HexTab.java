package tabs;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import javax.swing.SwingWorker;
import util.AppState;
import util.InstructionDecoder;

public class HexTab extends BaseTab {
    private JTextArea hexArea;
    private JTable disassemblyTable;
    private DefaultTableModel tableModel;
    private JTextArea explanationArea;
    private JButton disassembleButton;
    private JButton explainButton;
    private JSplitPane mainSplitPane;
    private JSplitPane rightSplitPane;
    
    public HexTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Hex content area
        hexArea = new JTextArea();
        hexArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        hexArea.setBackground(new Color(248, 248, 248));
        
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
        disassembleButton = new JButton("Disassemble Hex");
        disassembleButton.addActionListener(e -> disassembleHex());
        
        explainButton = new JButton("Explain Opcodes");
        explainButton.addActionListener(e -> explainOpcodes());
        explainButton.setEnabled(false);
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // Left panel: hex content with buttons
        JPanel leftPanel = new JPanel(new BorderLayout());
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(disassembleButton);
        buttonPanel.add(explainButton);
        
        leftPanel.add(new JLabel("Raw Hex Content:"), BorderLayout.NORTH);
        leftPanel.add(new JScrollPane(hexArea), BorderLayout.CENTER);
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
        hexArea.setText(content);
        tableModel.setRowCount(0); // Clear table
        explanationArea.setText("");
        explainButton.setEnabled(false);
    }
    
    @Override
    public void saveContent() {
        // Hex files are typically read-only, but allow saving if modified
        if (appState.getCurrentFile() != null) {
            try (FileWriter writer = new FileWriter(appState.getCurrentFile())) {
                writer.write(hexArea.getText());
                updateStatus("Saved: " + appState.getCurrentFile().getName());
            } catch (IOException e) {
                showError("Save Error", "Failed to save file: " + e.getMessage());
            }
        }
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
        String hexContent = hexArea.getText().trim();
        if (hexContent.isEmpty()) {
            showError("Disassemble Error", "No hex content to disassemble");
            return;
        }
        
        disassembleButton.setEnabled(false);
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
                            
                            // Use basic decoding for now
                            Object[] row = createBasicTableRow(address, instruction);
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
                disassembleButton.setEnabled(true);
                explainButton.setEnabled(true);
                updateStatus("Disassembly complete");
            }
        };
        
        worker.execute();
    }
    
    private Object[] createBasicTableRow(int address, int instruction) {
        // Basic decode without custom decoder for now
        int opcode = (instruction >>> 26) & 0x3F;  // [31:26]
        int rd = (instruction >>> 19) & 0x1F;      // [23:19] 
        int rs1 = (instruction >>> 14) & 0x1F;     // [18:14]
        int rs2 = (instruction >>> 9) & 0x1F;      // [13:9]
        int immediate = instruction & 0x1FF;       // [8:0]
        
        // Sign extend immediate
        if ((immediate & 0x100) != 0) {
            immediate |= 0xFFFFFE00;
        }
        
        String mnemonic = "OP_" + String.format("%02X", opcode);
        String comment = "Instruction at " + String.format("0x%08X", address);
        
        return new Object[] {
            String.format("0x%08X", address),           // Address
            String.format("0x%02X", opcode),            // Opcode
            String.format("R%d", rd),                   // RD
            String.format("R%d", rs1),                  // RS1
            String.format("R%d", rs2),                  // RS2
            String.valueOf(immediate),                  // IMM
            mnemonic,                                   // Mnemonic
            comment                                     // Comment
        };
    }
    
    private void explainOpcodes() {
        if (tableModel.getRowCount() == 0) {
            showInfo("No Instructions", "Please disassemble hex code first.");
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
            String opcode = (String) tableModel.getValueAt(i, 1);
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
        if (hexArea != null) hexArea.setText("");
        if (tableModel != null) tableModel.setRowCount(0);
        if (explanationArea != null) explanationArea.setText("");
        if (explainButton != null) explainButton.setEnabled(false);
    }
}
