package tabs;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.util.HashMap;
import java.util.Map;
import util.AppState;

/**
 * Tab for encoding instructions from opcode and operands to 32-bit hex/binary
 * Supports all CPU opcodes with appropriate instruction formats
 */
public class OpcodeEncoderTab extends BaseTab {
    private JComboBox<String> opcodeCombo;
    private JTextField rdField;
    private JTextField rs1Field;
    private JTextField rs2Field;
    private JTextField immField;
    private JLabel hexOutput;
    private JLabel binaryOutput;
    private JTextArea detailsOutput;
    private JButton encodeButton;
    private JButton clearButton;
    private JLabel formatLabel;
    
    // Opcode mapping (mnemonic -> opcode value)
    private static final Map<String, Integer> OPCODE_MAP = new HashMap<>();
    
    static {
        // ALU operations (0x00–0x1F)
        OPCODE_MAP.put("ADD", 0x00);
        OPCODE_MAP.put("SUB", 0x01);
        OPCODE_MAP.put("AND", 0x02);
        OPCODE_MAP.put("OR", 0x03);
        OPCODE_MAP.put("XOR", 0x04);
        OPCODE_MAP.put("NOT", 0x05);
        OPCODE_MAP.put("SHL", 0x06);
        OPCODE_MAP.put("SHR", 0x07);
        OPCODE_MAP.put("MUL", 0x08);
        OPCODE_MAP.put("DIV", 0x09);
        OPCODE_MAP.put("MOD", 0x0A);
        OPCODE_MAP.put("CMP", 0x0B);
        OPCODE_MAP.put("SAR", 0x0C);
        
        // Memory operations (0x20–0x2F)
        OPCODE_MAP.put("LOAD", 0x20);
        OPCODE_MAP.put("STORE", 0x21);
        OPCODE_MAP.put("LOADI", 0x22);
        
        // Control/Branch opcodes (0x30–0x3F)
        OPCODE_MAP.put("JMP", 0x30);
        OPCODE_MAP.put("JZ", 0x31);
        OPCODE_MAP.put("JNZ", 0x32);
        OPCODE_MAP.put("JC", 0x33);
        OPCODE_MAP.put("JNC", 0x34);
        OPCODE_MAP.put("JLT", 0x35);
        OPCODE_MAP.put("JGE", 0x36);
        OPCODE_MAP.put("JLE", 0x37);
        OPCODE_MAP.put("CALL", 0x38);
        OPCODE_MAP.put("RET", 0x39);
        OPCODE_MAP.put("PUSH", 0x3A);
        OPCODE_MAP.put("POP", 0x3B);
        
        // Set/Compare opcodes (0x40–0x4F)
        OPCODE_MAP.put("SETEQ", 0x40);
        OPCODE_MAP.put("SETNE", 0x41);
        OPCODE_MAP.put("SETLT", 0x42);
        OPCODE_MAP.put("SETGE", 0x43);
        OPCODE_MAP.put("SETLE", 0x44);
        OPCODE_MAP.put("SETGT", 0x45);
        
        // System/Privileged opcodes (0x50–0x5F)
        OPCODE_MAP.put("HALT", 0x50);
        OPCODE_MAP.put("INT", 0x51);
    }
    
    public OpcodeEncoderTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Opcode selection
        String[] opcodes = OPCODE_MAP.keySet().toArray(new String[0]);
        java.util.Arrays.sort(opcodes);
        opcodeCombo = new JComboBox<>(opcodes);
        opcodeCombo.addActionListener(_ -> updateFormatInfo());
        
        // Register fields
        rdField = new JTextField(5);
        rs1Field = new JTextField(5);
        rs2Field = new JTextField(5);
        immField = new JTextField(10);
        
        // Format info
        formatLabel = new JLabel("Format: ");
        formatLabel.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        
        // Output labels
        hexOutput = new JLabel("Hex: ");
        hexOutput.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        
        binaryOutput = new JLabel("Binary: ");
        binaryOutput.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        
        // Details output
        detailsOutput = new JTextArea(8, 50);
        detailsOutput.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        detailsOutput.setEditable(false);
        detailsOutput.setBackground(new Color(248, 248, 248));
        detailsOutput.setBorder(new EmptyBorder(5, 5, 5, 5));
        
        // Buttons
        encodeButton = new JButton("Encode");
        encodeButton.addActionListener(_ -> encodeInstruction());
        
        clearButton = new JButton("Clear");
        clearButton.addActionListener(_ -> clearAll());
        
        // Initialize format info
        updateFormatInfo();
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));
        
        // Top panel - Opcode selection
        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        topPanel.setBorder(new TitledBorder("Instruction"));
        topPanel.add(new JLabel("Opcode:"));
        topPanel.add(opcodeCombo);
        topPanel.add(formatLabel);
        
        // Middle panel - Operands
        JPanel middlePanel = new JPanel(new GridBagLayout());
        middlePanel.setBorder(new TitledBorder("Operands"));
        
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        
        // RD field
        gbc.gridx = 0; gbc.gridy = 0;
        middlePanel.add(new JLabel("RD (0-31):"), gbc);
        gbc.gridx = 1;
        middlePanel.add(rdField, gbc);
        
        // RS1 field
        gbc.gridx = 2; gbc.gridy = 0;
        middlePanel.add(new JLabel("RS1 (0-31):"), gbc);
        gbc.gridx = 3;
        middlePanel.add(rs1Field, gbc);
        
        // RS2 field
        gbc.gridx = 0; gbc.gridy = 1;
        middlePanel.add(new JLabel("RS2 (0-31):"), gbc);
        gbc.gridx = 1;
        middlePanel.add(rs2Field, gbc);
        
        // Immediate field
        gbc.gridx = 2; gbc.gridy = 1;
        middlePanel.add(new JLabel("IMM:"), gbc);
        gbc.gridx = 3;
        middlePanel.add(immField, gbc);
        
        // Buttons
        gbc.gridx = 0; gbc.gridy = 2;
        gbc.gridwidth = 2;
        JPanel buttonPanel = new JPanel(new FlowLayout());
        buttonPanel.add(encodeButton);
        buttonPanel.add(clearButton);
        middlePanel.add(buttonPanel, gbc);
        
        // Output panel
        JPanel outputPanel = new JPanel(new BorderLayout());
        outputPanel.setBorder(new TitledBorder("Encoded Instruction"));
        
        JPanel outputLabels = new JPanel(new GridLayout(2, 1));
        outputLabels.add(hexOutput);
        outputLabels.add(binaryOutput);
        outputPanel.add(outputLabels, BorderLayout.NORTH);
        
        outputPanel.add(new JScrollPane(detailsOutput), BorderLayout.CENTER);
        
        // Layout assembly
        add(topPanel, BorderLayout.NORTH);
        add(middlePanel, BorderLayout.CENTER);
        add(outputPanel, BorderLayout.SOUTH);
    }
    
    private void updateFormatInfo() {
        String opcode = (String) opcodeCombo.getSelectedItem();
        if (opcode == null) return;
        
        int opcodeValue = OPCODE_MAP.get(opcode);
        
        // Update format based on opcode type
        if (opcodeValue >= 0x00 && opcodeValue <= 0x1F) {
            formatLabel.setText("Format: " + opcode + " RD, RS1, RS2");
        } else if (opcodeValue == 0x20) {
            formatLabel.setText("Format: LOAD RD, [IMM]");
        } else if (opcodeValue == 0x21) {
            formatLabel.setText("Format: STORE RD, [IMM]");
        } else if (opcodeValue == 0x22) {
            formatLabel.setText("Format: LOADI RD, IMM");
        } else if (opcodeValue >= 0x30 && opcodeValue <= 0x3F) {
            if (opcodeValue == 0x39) { // RET
                formatLabel.setText("Format: RET");
            } else if (opcodeValue == 0x3A) { // PUSH
                formatLabel.setText("Format: PUSH RD");
            } else if (opcodeValue == 0x3B) { // POP
                formatLabel.setText("Format: POP RD");
            } else {
                formatLabel.setText("Format: " + opcode + " [IMM]");
            }
        } else if (opcodeValue >= 0x40 && opcodeValue <= 0x4F) {
            formatLabel.setText("Format: " + opcode + " RD, RS1, RS2");
        } else if (opcodeValue >= 0x50 && opcodeValue <= 0x5F) {
            formatLabel.setText("Format: " + opcode);
        }
    }
    
    private void encodeInstruction() {
        String opcode = (String) opcodeCombo.getSelectedItem();
        if (opcode == null) {
            showError("Error", "Please select an opcode.");
            return;
        }
        
        int opcodeValue = OPCODE_MAP.get(opcode);
        
        try {
            // Parse operands
            int rd = parseRegister(rdField.getText(), "RD");
            int rs1 = parseRegister(rs1Field.getText(), "RS1");
            int rs2 = parseRegister(rs2Field.getText(), "RS2");
            int imm = parseImmediate(immField.getText());
            
            // Encode instruction based on format
            int instruction = encodeInstructionValue(opcodeValue, rd, rs1, rs2, imm);
            
            // Display results
            String hexStr = String.format("0x%08X", instruction);
            String binStr = String.format("%32s", Integer.toBinaryString(instruction)).replace(' ', '0');
            
            hexOutput.setText("Hex: " + hexStr);
            binaryOutput.setText("Binary: " + binStr);
            
            // Generate detailed output
            StringBuilder details = new StringBuilder();
            details.append("Instruction: ").append(opcode).append("\n");
            details.append("Encoded: ").append(hexStr).append("\n");
            details.append("Binary:  ").append(binStr).append("\n");
            details.append("         ").append("^^^^^^  ^^^^^ ^^^^^ ^^^^^ ^^^^^^^^^^^^^^^^^^^\n");
            details.append("         ").append("opcode   rd   rs1   rs2     immediate\n\n");
            
            details.append("Field Breakdown:\n");
            details.append("  Opcode (31:26): ").append(String.format("0x%02X", opcodeValue)).append(" (").append(opcodeValue).append(") - ").append(opcode).append("\n");
            details.append("  RD     (23:19): ").append(String.format("R%d", rd)).append(" (").append(rd).append(")\n");
            details.append("  RS1    (18:14): ").append(String.format("R%d", rs1)).append(" (").append(rs1).append(")\n");
            details.append("  RS2    (13:9):  ").append(String.format("R%d", rs2)).append(" (").append(rs2).append(")\n");
            details.append("  IMM    (18:0):  ").append(String.format("0x%05X", imm & 0x7FFFF)).append(" (").append(imm).append(")\n\n");
            
            // Add assembly format
            details.append("Assembly: ").append(generateAssembly(opcode, rd, rs1, rs2, imm)).append("\n");
            
            // Add Verilog testbench format
            details.append("Verilog Testbench:\n");
            if (opcodeValue >= 0x00 && opcodeValue <= 0x1F || opcodeValue >= 0x40 && opcodeValue <= 0x4F) {
                details.append("  mem[addr] = encode_rrr(6'h").append(String.format("%02X", opcodeValue))
                       .append(", 5'd").append(rd).append(", 5'd").append(rs1).append(", 5'd").append(rs2).append(");");
            } else {
                details.append("  mem[addr] = encode_ri(6'h").append(String.format("%02X", opcodeValue))
                       .append(", 5'd").append(rd).append(", 5'd").append(rs1).append(", 19'd").append(imm).append(");");
            }
            
            detailsOutput.setText(details.toString());
            updateStatus("Instruction encoded successfully");
            
        } catch (NumberFormatException e) {
            showError("Parse Error", e.getMessage());
        }
    }
    
    private int parseRegister(String text, String fieldName) throws NumberFormatException {
        if (text.isEmpty()) return 0;
        
        try {
            int value = Integer.parseInt(text);
            if (value < 0 || value > 31) {
                throw new NumberFormatException(fieldName + " must be between 0 and 31");
            }
            return value;
        } catch (NumberFormatException e) {
            throw new NumberFormatException("Invalid " + fieldName + " value: " + text);
        }
    }
    
    private int parseImmediate(String text) throws NumberFormatException {
        if (text.isEmpty()) return 0;
        
        try {
            if (text.startsWith("0x") || text.startsWith("0X")) {
                return Integer.parseInt(text.substring(2), 16);
            } else {
                return Integer.parseInt(text);
            }
        } catch (NumberFormatException e) {
            throw new NumberFormatException("Invalid immediate value: " + text);
        }
    }
    
    private int encodeInstructionValue(int opcode, int rd, int rs1, int rs2, int imm) {
        // 32-bit instruction format: [31:26] opcode, [25:24] reserved, [23:19] rd, [18:14] rs1, [13:9] rs2, [18:0] immediate
        int instruction = 0;
        
        // Set opcode (6 bits)
        instruction |= (opcode & 0x3F) << 26;
        
        // Set rd (5 bits)
        instruction |= (rd & 0x1F) << 19;
        
        // Set rs1 (5 bits)
        instruction |= (rs1 & 0x1F) << 14;
        
        // Set rs2 (5 bits)
        instruction |= (rs2 & 0x1F) << 9;
        
        // Set immediate (19 bits for most instructions)
        instruction |= (imm & 0x7FFFF);
        
        return instruction;
    }
    
    private String generateAssembly(String opcode, int rd, int rs1, int rs2, int imm) {
        int opcodeValue = OPCODE_MAP.get(opcode);
        
        if (opcodeValue >= 0x00 && opcodeValue <= 0x1F) {
            if (opcodeValue == 0x05) { // NOT
                return String.format("%s R%d, R%d", opcode, rd, rs1);
            } else {
                return String.format("%s R%d, R%d, R%d", opcode, rd, rs1, rs2);
            }
        } else if (opcodeValue == 0x20) { // LOAD
            return String.format("LOAD R%d, [0x%X]", rd, imm);
        } else if (opcodeValue == 0x21) { // STORE
            return String.format("STORE R%d, [0x%X]", rd, imm);
        } else if (opcodeValue == 0x22) { // LOADI
            return String.format("LOADI R%d, 0x%X", rd, imm);
        } else if (opcodeValue >= 0x30 && opcodeValue <= 0x38) { // Branches and CALL
            return String.format("%s 0x%X", opcode, imm);
        } else if (opcodeValue == 0x39) { // RET
            return "RET";
        } else if (opcodeValue == 0x3A) { // PUSH
            return String.format("PUSH R%d", rd);
        } else if (opcodeValue == 0x3B) { // POP
            return String.format("POP R%d", rd);
        } else if (opcodeValue >= 0x40 && opcodeValue <= 0x4F) { // Set operations
            return String.format("%s R%d, R%d, R%d", opcode, rd, rs1, rs2);
        } else if (opcodeValue >= 0x50 && opcodeValue <= 0x5F) { // System
            return opcode;
        }
        
        return String.format("%s R%d, R%d, R%d", opcode, rd, rs1, rs2);
    }
    
    private void clearAll() {
        rdField.setText("");
        rs1Field.setText("");
        rs2Field.setText("");
        immField.setText("");
        hexOutput.setText("Hex: ");
        binaryOutput.setText("Binary: ");
        detailsOutput.setText("");
        updateStatus("Cleared");
    }
    
    @Override
    public void loadContent(String content) {
        // Parse content if it's in a specific format
        clearAll();
    }
    
    @Override
    public void saveContent() {
        // Not applicable for this tab
    }
    
    @Override
    public void clearContent() {
        clearAll();
    }
}
