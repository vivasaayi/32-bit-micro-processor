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
    private JTextField binaryField; // For copiable binary
    private JLabel binaryLabel;
    private JTextArea decodedOutput;
    private JPanel fieldsPanel;
    private JButton decodeButton;
    private JButton clearButton;
    
    // Field display labels
    private JTextField opcodeField, rdField, rs1Field, rs2Field, imm19Field, imm9Field, mnemonicField;
    private JTextArea historyArea;
    
    // Binary breakdown fields (copiable)
    private JTextField opcodeBinField, rdBinField, rs1BinField, rs2BinField, imm19BinField, imm9BinField;
    
    public InstructionDecoderTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Input field
        inputField = new JTextField(25);
        inputField.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        inputField.addActionListener(_ -> decodeInstruction());

        // Binary display (copiable)
        binaryField = new JTextField();
        binaryField.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        binaryField.setEditable(false);
        binaryField.setBackground(new Color(248, 248, 248));
        binaryField.setBorder(new EmptyBorder(2, 2, 2, 2));
        binaryField.setDragEnabled(true);

        // Buttons
        decodeButton = new JButton("Decode");
        decodeButton.addActionListener(_ -> decodeInstruction());
        clearButton = new JButton("Clear");
        clearButton.addActionListener(_ -> clearAll());

        // Fields panel as grid of labels and text fields
        fieldsPanel = new JPanel(new GridLayout(7, 2, 5, 5));
        fieldsPanel.setBorder(new TitledBorder("Instruction Fields"));
        opcodeField = createFieldText();
        rdField = createFieldText();
        rs1Field = createFieldText();
        rs2Field = createFieldText();
        imm19Field = createFieldText();
        imm9Field = createFieldText();
        mnemonicField = createFieldText();
        fieldsPanel.add(new JLabel("Opcode (bits 31:26):")); fieldsPanel.add(opcodeField);
        fieldsPanel.add(new JLabel("RD (bits 23:19):")); fieldsPanel.add(rdField);
        fieldsPanel.add(new JLabel("RS1 (bits 18:14):")); fieldsPanel.add(rs1Field);
        fieldsPanel.add(new JLabel("RS2 (bits 13:9):")); fieldsPanel.add(rs2Field);
        fieldsPanel.add(new JLabel("IMM[18:0] (bits 18:0):")); fieldsPanel.add(imm19Field);
        fieldsPanel.add(new JLabel("IMM[8:0] (bits 8:0):")); fieldsPanel.add(imm9Field);
        fieldsPanel.add(new JLabel("Mnemonic:")); fieldsPanel.add(mnemonicField);

        // Decoded output area (taller)
        decodedOutput = new JTextArea(16, 50);
        decodedOutput.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        decodedOutput.setEditable(false);
        decodedOutput.setBackground(new Color(248, 248, 248));
        decodedOutput.setBorder(new EmptyBorder(5, 5, 5, 5));

        // History area
        historyArea = new JTextArea(8, 50);
        historyArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        historyArea.setEditable(false);
        historyArea.setBackground(new Color(240, 240, 255));
        historyArea.setBorder(new TitledBorder("Decode History"));

        // Binary breakdown fields (copiable)
        opcodeBinField = createFieldText();
        rdBinField = createFieldText();
        rs1BinField = createFieldText();
        rs2BinField = createFieldText();
        imm19BinField = createFieldText();
        imm9BinField = createFieldText();
    }

    private JTextField createFieldText() {
        JTextField tf = new JTextField();
        tf.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        tf.setEditable(false);
        tf.setBackground(new Color(248, 248, 248));
        tf.setBorder(new EmptyBorder(2, 2, 2, 2));
        return tf;
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
        // Middle panel - Binary display (copiable)
        JPanel middlePanel = new JPanel();
        middlePanel.setLayout(new BoxLayout(middlePanel, BoxLayout.Y_AXIS));
        middlePanel.setBorder(new TitledBorder("Binary Representation"));
        middlePanel.add(binaryField);
        JPanel binGrid = new JPanel(new GridLayout(2, 6, 4, 2));
        binGrid.add(new JLabel("Opcode"));
        binGrid.add(new JLabel("RD"));
        binGrid.add(new JLabel("RS1"));
        binGrid.add(new JLabel("RS2"));
        binGrid.add(new JLabel("IMM[18:0]"));
        binGrid.add(new JLabel("IMM[8:0]"));
        binGrid.add(opcodeBinField);
        binGrid.add(rdBinField);
        binGrid.add(rs1BinField);
        binGrid.add(rs2BinField);
        binGrid.add(imm19BinField);
        binGrid.add(imm9BinField);
        middlePanel.add(binGrid);
        // Fields panel (already set up)
        // Bottom panel - Detailed output and history
        JPanel bottomPanel = new JPanel(new BorderLayout());
        bottomPanel.setBorder(new TitledBorder("Detailed Breakdown & History"));
        bottomPanel.add(new JScrollPane(decodedOutput), BorderLayout.CENTER);
        bottomPanel.add(new JScrollPane(historyArea), BorderLayout.SOUTH);
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
                value = (int)Long.parseLong(input, 16);
            }
        } catch (Exception ex) {
            showError("Parse Error", "Invalid input. Please enter a valid 32-bit hex or binary value.");
            return;
        }
        // Display binary representation (copiable)
        String binStr = String.format("%32s", Integer.toBinaryString(value)).replace(' ', '0');
        binaryField.setText(binStr);
        // Extract fields
        int opcode = (value >>> 26) & 0x3F;
        int rd = (value >>> 19) & 0x1F;
        int rs1 = (value >>> 14) & 0x1F;
        int rs2 = (value >>> 9) & 0x1F;
        int imm19 = value & 0x7FFFF;
        int imm9 = value & 0x1FF;
        // Set binary fields (copiable)
        opcodeBinField.setText(String.format("%6s", Integer.toBinaryString(opcode)).replace(' ', '0'));
        rdBinField.setText(String.format("%5s", Integer.toBinaryString(rd)).replace(' ', '0'));
        rs1BinField.setText(String.format("%5s", Integer.toBinaryString(rs1)).replace(' ', '0'));
        rs2BinField.setText(String.format("%5s", Integer.toBinaryString(rs2)).replace(' ', '0'));
        imm19BinField.setText(String.format("%19s", Integer.toBinaryString(imm19)).replace(' ', '0'));
        imm9BinField.setText(String.format("%9s", Integer.toBinaryString(imm9)).replace(' ', '0'));
        // Update field text fields
        opcodeField.setText(String.format("0x%02X (%d)", opcode, opcode));
        rdField.setText(String.format("R%d", rd));
        rs1Field.setText(String.format("R%d", rs1));
        rs2Field.setText(String.format("R%d", rs2));
        imm19Field.setText(String.format("0x%05X (%d)", imm19, imm19));
        imm9Field.setText(String.format("0x%03X (%d)", imm9, imm9));
        mnemonicField.setText(util.InstructionDecoder.getOpcodeName(opcode));
        // Generate detailed breakdown
        StringBuilder sb = new StringBuilder();
        sb.append("Instruction: 0x").append(String.format("%08X", value)).append("\n");
        sb.append("Binary:      ").append(binStr).append("\n");
        sb.append("             ").append("^^^^^^  ^^^^^ ^^^^^ ^^^^^ ^^^^^^^^^^^^^^^^^^^\n");
        sb.append("             ").append("opcode   rd   rs1   rs2     immediate\n\n");
        sb.append("Field Breakdown:\n");
        sb.append("  Opcode (31:26): ").append(String.format("0x%02X", opcode)).append(" (").append(opcode).append(") - ").append(util.InstructionDecoder.getOpcodeName(opcode)).append("\n");
        sb.append("  RD     (23:19): ").append(String.format("R%d", rd)).append(" (register ").append(rd).append(")\n");
        sb.append("  RS1    (18:14): ").append(String.format("R%d", rs1)).append(" (register ").append(rs1).append(")\n");
        sb.append("  RS2    (13:9):  ").append(String.format("R%d", rs2)).append(" (register ").append(rs2).append(")\n");
        sb.append("  IMM[18:0]  (18:0): ").append(String.format("0x%05X", imm19)).append(" (").append(imm19).append(")\n");
        sb.append("  IMM[8:0]   (8:0):  ").append(String.format("0x%03X", imm9)).append(" (").append(imm9).append(")\n\n");
        String mnemonic = util.InstructionDecoder.getOpcodeName(opcode);
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
        // Add to history
        historyArea.append("[" + input + "]\n" + sb.toString() + "\n-----------------------------\n");
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
        binaryField.setText("");
        opcodeField.setText("");
        rdField.setText("");
        rs1Field.setText("");
        rs2Field.setText("");
        imm19Field.setText("");
        imm9Field.setText("");
        mnemonicField.setText("");
        decodedOutput.setText("");
        // Clear binary fields (copiable)
        opcodeBinField.setText("");
        rdBinField.setText("");
        rs1BinField.setText("");
        rs2BinField.setText("");
        imm19BinField.setText("");
        imm9BinField.setText("");
        // Do not clear history
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
