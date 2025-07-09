package tabs;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.border.TitledBorder;
import java.awt.*;
import util.AppState;
import util.InstructionDecoder;

/**
 * Tab for decoding 32-bit instructions
 * Supports hex and binary input, displays 6-bit opcode breakdown
 */
public class InstructionDecoderTab extends BaseTab {
    private JTextField inputField;
    private JLabel binaryLabel;
    private JTextArea decodedOutput;
    private JPanel fieldsPanel;
    private JButton decodeButton;
    private JButton clearButton;
    
    // Field display labels
    private JLabel opcodeLabel;
    private JLabel rdLabel;
    private JLabel rs1Label;
    private JLabel rs2Label;
    private JLabel imm19Label;
    private JLabel imm9Label;
    private JLabel mnemonicLabel;
    
    public InstructionDecoderTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Input field
        inputField = new JTextField(25);
        inputField.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        inputField.addActionListener(_ -> decodeInstruction());
        
        // Binary display
        binaryLabel = new JLabel("32-bit Binary: ");
        binaryLabel.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        
        // Buttons
        decodeButton = new JButton("Decode");
        decodeButton.addActionListener(_ -> decodeInstruction());
        
        clearButton = new JButton("Clear");
        clearButton.addActionListener(_ -> clearAll());
        
        // Fields panel
        fieldsPanel = new JPanel(new GridLayout(7, 2, 5, 5));
        fieldsPanel.setBorder(new TitledBorder("Instruction Fields"));
        
        // Field labels
        opcodeLabel = createFieldLabel("Opcode (31:26):");
        rdLabel = createFieldLabel("RD (23:19):");
        rs1Label = createFieldLabel("RS1 (18:14):");
        rs2Label = createFieldLabel("RS2 (13:9):");
        imm19Label = createFieldLabel("IMM[18:0] (18:0):");
        imm9Label = createFieldLabel("IMM[8:0] (8:0):");
        mnemonicLabel = createFieldLabel("Mnemonic:");
        
        // Decoded output area
        decodedOutput = new JTextArea(8, 50);
        decodedOutput.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        decodedOutput.setEditable(false);
        decodedOutput.setBackground(new Color(248, 248, 248));
        decodedOutput.setBorder(new EmptyBorder(5, 5, 5, 5));
    }
    
    private JLabel createFieldLabel(String text) {
        JLabel label = new JLabel(text);
        label.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        return label;
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        setBorder(new EmptyBorder(10, 10, 10, 10));
        
        // Top panel - Input
        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        topPanel.setBorder(new TitledBorder("Input"));
        topPanel.add(new JLabel("Hex (0x12345678) or Binary (1101...):"));
        topPanel.add(inputField);
        topPanel.add(decodeButton);
        topPanel.add(clearButton);
        
        // Middle panel - Binary display
        JPanel middlePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        middlePanel.setBorder(new TitledBorder("Binary Representation"));
        middlePanel.add(binaryLabel);
        
        // Fields panel setup
        fieldsPanel.add(new JLabel("Opcode (bits 31:26):"));
        fieldsPanel.add(opcodeLabel);
        fieldsPanel.add(new JLabel("RD (bits 23:19):"));
        fieldsPanel.add(rdLabel);
        fieldsPanel.add(new JLabel("RS1 (bits 18:14):"));
        fieldsPanel.add(rs1Label);
        fieldsPanel.add(new JLabel("RS2 (bits 13:9):"));
        fieldsPanel.add(rs2Label);
        fieldsPanel.add(new JLabel("IMM[18:0] (bits 18:0):"));
        fieldsPanel.add(imm19Label);
        fieldsPanel.add(new JLabel("IMM[8:0] (bits 8:0):"));
        fieldsPanel.add(imm9Label);
        fieldsPanel.add(new JLabel("Mnemonic:"));
        fieldsPanel.add(mnemonicLabel);
        
        // Bottom panel - Detailed output
        JPanel bottomPanel = new JPanel(new BorderLayout());
        bottomPanel.setBorder(new TitledBorder("Detailed Breakdown"));
        bottomPanel.add(new JScrollPane(decodedOutput), BorderLayout.CENTER);
        
        // Layout
        add(topPanel, BorderLayout.NORTH);
        
        JPanel centerPanel = new JPanel(new BorderLayout());
        centerPanel.add(middlePanel, BorderLayout.NORTH);
        centerPanel.add(fieldsPanel, BorderLayout.CENTER);
        add(centerPanel, BorderLayout.CENTER);
        
        add(bottomPanel, BorderLayout.SOUTH);
    }
    
    private void decodeInstruction() {
        String input = inputField.getText().trim();
        if (input.isEmpty()) {
            showError("Input Error", "Please enter a value.");
            return;
        }
        
        int value;
        try {
            if (input.startsWith("0x") || input.startsWith("0X")) {
                value = (int)Long.parseLong(input.substring(2), 16);
            } else if (input.matches("[01]{1,32}")) {
                value = Integer.parseUnsignedInt(input, 2);
            } else {
                // Try to parse as hex without 0x prefix
                value = (int)Long.parseLong(input, 16);
            }
        } catch (Exception ex) {
            showError("Parse Error", "Invalid input. Please enter a valid 32-bit hex or binary value.");
            return;
        }
        
        // Display binary representation
        String binStr = String.format("%32s", Integer.toBinaryString(value)).replace(' ', '0');
        binaryLabel.setText("32-bit Binary: " + binStr);
        
        // Extract fields
        int opcode = (value >>> 26) & 0x3F;  // 6 bits
        int rd = (value >>> 19) & 0x1F;      // 5 bits
        int rs1 = (value >>> 14) & 0x1F;     // 5 bits
        int rs2 = (value >>> 9) & 0x1F;      // 5 bits
        int imm19 = value & 0x7FFFF;         // 19 bits
        int imm9 = value & 0x1FF;            // 9 bits
        
        // Update field labels
        opcodeLabel.setText(String.format("0x%02X (%d)", opcode, opcode));
        rdLabel.setText(String.format("R%d", rd));
        rs1Label.setText(String.format("R%d", rs1));
        rs2Label.setText(String.format("R%d", rs2));
        imm19Label.setText(String.format("0x%05X (%d)", imm19, imm19));
        imm9Label.setText(String.format("0x%03X (%d)", imm9, imm9));
        mnemonicLabel.setText(InstructionDecoder.getOpcodeName(opcode));
        
        // Generate detailed breakdown
        StringBuilder sb = new StringBuilder();
        sb.append("Instruction: 0x").append(String.format("%08X", value)).append("\n");
        sb.append("Binary:      ").append(binStr).append("\n");
        sb.append("             ").append("^^^^^^  ^^^^^ ^^^^^ ^^^^^ ^^^^^^^^^^^^^^^^^^^\n");
        sb.append("             ").append("opcode   rd   rs1   rs2     immediate\n\n");
        
        sb.append("Field Breakdown:\n");
        sb.append("  Opcode (31:26): ").append(String.format("0x%02X", opcode)).append(" (").append(opcode).append(") - ").append(InstructionDecoder.getOpcodeName(opcode)).append("\n");
        sb.append("  RD     (23:19): ").append(String.format("R%d", rd)).append(" (register ").append(rd).append(")\n");
        sb.append("  RS1    (18:14): ").append(String.format("R%d", rs1)).append(" (register ").append(rs1).append(")\n");
        sb.append("  RS2    (13:9):  ").append(String.format("R%d", rs2)).append(" (register ").append(rs2).append(")\n");
        sb.append("  IMM[18:0]  (18:0): ").append(String.format("0x%05X", imm19)).append(" (").append(imm19).append(")\n");
        sb.append("  IMM[8:0]   (8:0):  ").append(String.format("0x%03X", imm9)).append(" (").append(imm9).append(")\n\n");
        
        // Add instruction format information
        String mnemonic = InstructionDecoder.getOpcodeName(opcode);
        sb.append("Instruction Format:\n");
        if (opcode >= 0x00 && opcode <= 0x1F) {
            sb.append("  Type: ALU Operation\n");
            sb.append("  Format: ").append(mnemonic).append(" RD, RS1, RS2\n");
            sb.append("  Operation: R").append(rd).append(" = R").append(rs1).append(" ").append(getOperationSymbol(opcode)).append(" R").append(rs2).append("\n");
        } else if (opcode >= 0x20 && opcode <= 0x2F) {
            sb.append("  Type: Memory Operation\n");
            if (opcode == 0x20) {
                sb.append("  Format: LOAD RD, [address]\n");
                sb.append("  Operation: R").append(rd).append(" = MEM[0x").append(String.format("%05X", imm19)).append("]\n");
            } else if (opcode == 0x21) {
                sb.append("  Format: STORE RD, [address]\n");
                sb.append("  Operation: MEM[0x").append(String.format("%05X", imm19)).append("] = R").append(rd).append("\n");
            } else if (opcode == 0x22) {
                sb.append("  Format: LOADI RD, imm\n");
                sb.append("  Operation: R").append(rd).append(" = 0x").append(String.format("%05X", imm19)).append("\n");
            }
        } else if (opcode >= 0x30 && opcode <= 0x3F) {
            sb.append("  Type: Control/Branch Operation\n");
            sb.append("  Format: ").append(mnemonic).append(" [target]\n");
        } else if (opcode >= 0x40 && opcode <= 0x4F) {
            sb.append("  Type: Set/Compare Operation\n");
            sb.append("  Format: ").append(mnemonic).append(" RD, RS1, RS2\n");
        } else if (opcode >= 0x50 && opcode <= 0x5F) {
            sb.append("  Type: System/Privileged Operation\n");
            sb.append("  Format: ").append(mnemonic).append("\n");
        }
        
        decodedOutput.setText(sb.toString());
        updateStatus("Instruction decoded successfully");
    }
    
    private String getOperationSymbol(int opcode) {
        switch (opcode) {
            case 0x00: return "+";
            case 0x01: return "-";
            case 0x02: return "&";
            case 0x03: return "|";
            case 0x04: return "^";
            case 0x05: return "~";
            case 0x06: return "<<";
            case 0x07: return ">>";
            case 0x08: return "*";
            case 0x09: return "/";
            case 0x0A: return "%";
            case 0x0B: return "CMP";
            case 0x0C: return ">>>";
            default: return "?";
        }
    }
    
    private void clearAll() {
        inputField.setText("");
        binaryLabel.setText("32-bit Binary: ");
        opcodeLabel.setText("");
        rdLabel.setText("");
        rs1Label.setText("");
        rs2Label.setText("");
        imm19Label.setText("");
        imm9Label.setText("");
        mnemonicLabel.setText("");
        decodedOutput.setText("");
        updateStatus("Cleared");
    }
    
    @Override
    public void loadContent(String content) {
        inputField.setText(content);
        if (!content.isEmpty()) {
            decodeInstruction();
        }
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
