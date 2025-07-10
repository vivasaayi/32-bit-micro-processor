package tabs;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import java.util.List;
import java.util.ArrayList;
import util.AppState;
import util.InstructionDecoder;
import java.util.Objects;

public class SimulationLogTab extends BaseTab {
    private JTextArea logArea;
    private JTable decodedTable;
    private DefaultTableModel decodedTableModel;
    private JPanel currentRegisterPanel;
    private JTable historyTable;
    private DefaultTableModel historyTableModel;
    private JSplitPane mainSplitPane;
    private JSplitPane rightSplitPane;
    private JSplitPane bottomSplitPane;
    
    // For tracking register changes
    private Map<Integer, Set<Integer>> instructionRegisterChanges = new HashMap<>();
    private Map<Integer, Map<Integer, Long>> instructionRegisterValues = new HashMap<>();
    private int currentInstructionRow = -1;
    private Map<Integer, Long> currentRegisterValues = new HashMap<>();
    private JLabel[] registerLabels; // PC + Flags + R0-R31
    
    // Paging for history table
    private int currentPage = 0;
    private final int rowsPerPage = 100;
    private int totalPages = 1;
    private JButton prevPageButton;
    private JButton nextPageButton;
    private JLabel pageInfoLabel;
    
    public SimulationLogTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);

        System.out.println("Length of JLables:" + registerLabels.length);
    }
    
    @Override
    protected void initializeComponents() {
        // Always initialize registerLabels here!
        registerLabels = new JLabel[34];
        System.out.println("Initializing components...");
        System.out.println("Length of JLabels:" + registerLabels.length);

        logArea = new JTextArea();
        logArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        logArea.setEditable(false);
        logArea.setBackground(Color.BLACK);
        logArea.setForeground(Color.GREEN);
        
        // Decoded instructions table
        String[] decodedColumns = {"PC", "OpCode", "Mnemonic", "RD", "RS1", "RS2", "IMM", "Description"};
        decodedTableModel = new DefaultTableModel(decodedColumns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        decodedTable = new JTable(decodedTableModel);
        decodedTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        decodedTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        
        // Initialize current register values (ensure map is created)
        if (currentRegisterValues == null) {
            currentRegisterValues = new HashMap<>();
        }
        for (int i = 0; i < 34; i++) {
            currentRegisterValues.put(i, 0L);
        }
        
        // Create current register display panel
        createCurrentRegisterPanel();
        
        // Create history table for register states after each instruction
        createHistoryTable();
        
        // Add selection listeners after tables are created
        addTableSelectionListeners();
        
        // Add modern features to history table
        addModernHistoryTableFeatures();
    }
    private void addTableSelectionListeners() {
        decodedTable.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                int selectedRow = decodedTable.getSelectedRow();
                if (selectedRow >= 0) {
                    currentInstructionRow = selectedRow;
                    updateCurrentRegisterDisplay();
                    highlightHistoryRow(selectedRow);
                    currentRegisterPanel.revalidate();
                    currentRegisterPanel.repaint();
                }
            }
        });
        historyTable.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                int selectedRow = historyTable.getSelectedRow();
                if (selectedRow >= 0) {
                    decodedTable.setRowSelectionInterval(selectedRow, selectedRow);
                    currentInstructionRow = selectedRow;
                    updateCurrentRegisterDisplay();
                    currentRegisterPanel.revalidate();
                    currentRegisterPanel.repaint();
                }
            }
        });
    }
    
    private void createCurrentRegisterPanel() {
        currentRegisterPanel = new JPanel();
        currentRegisterPanel.setLayout(new GridLayout(6, 6, 2, 2)); // 6x6 grid for 34 registers + padding
        currentRegisterPanel.setBorder(BorderFactory.createTitledBorder("Current Register State (Hex | Binary | Decimal)"));
        
        // Initialize register labels array only if not already created
        // Do NOT re-initialize if it already exists - this would clear all references!
        
        // Create labels for each register
        String[] registerNames = new String[34];
        registerNames[0] = "PC";
        registerNames[1] = "FL";
        for (int i = 0; i < 32; i++) {
            registerNames[i + 2] = "R" + i;
        }
        
        for (int i = 0; i < 34; i++) {
            System.out.println("Creating label for register: " + registerNames[i]);
            registerLabels[i] = createRegisterLabel(registerNames[i], 0L);
            currentRegisterPanel.add(registerLabels[i]);
        }
    }
    
    private JLabel createRegisterLabel(String name, long value) {
        JLabel label = new JLabel();
        label.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(Color.GRAY),
            BorderFactory.createEmptyBorder(2, 4, 2, 4)
        ));
        label.setOpaque(true);
        label.setBackground(Color.WHITE);
        label.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 8));
        updateRegisterLabel(label, name, value, false);
        return label;
    }
    
    private void updateRegisterLabel(JLabel label, String name, long value, boolean changed) {
        System.out.println("Update Register label called");
        System.out.println(label);
        System.out.println(name);
        System.out.println(value);
        System.out.println(changed);

        if (label == null) return;
        int intValue = (int) value;
        String hex = String.format("0x%08X", intValue);
        String binary = String.format("%32s", Integer.toBinaryString(intValue)).replace(' ', '0');
        String decimal = String.valueOf(intValue);
        // Plain text, 4 lines: name, hex, binary, decimal
        String text = name + "\n" + hex + "\n" + binary + "\n" + decimal;
        System.out.println(text);
        label.setText("<html>" + text.replace("\n", "<br>") + "</html>"); // Use <br> for multiline, but no other HTML
        label.setBackground(changed ? Color.GREEN : Color.WHITE);
        label.setForeground(Color.BLACK);
        label.setPreferredSize(new Dimension(110, 55));
        label.revalidate();
        label.repaint();
    }
    
    private void createHistoryTable() {
        // Create modern history table with one row per instruction
        String[] historyColumns = new String[36]; // Instruction + PC + Flags + R0-R31
        historyColumns[0] = "Instruction";
        historyColumns[1] = "PC";
        historyColumns[2] = "Flags";
        for (int i = 0; i < 32; i++) {
            historyColumns[i + 3] = "R" + i;
        }
        
        historyTableModel = new DefaultTableModel(historyColumns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        
        historyTable = new JTable(historyTableModel);
        historyTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        historyTable.setRowHeight(22);
        historyTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        historyTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
        historyTable.getTableHeader().setFont(new Font(Font.MONOSPACED, Font.BOLD, 11));
        historyTable.getTableHeader().setBackground(new Color(240, 240, 240));
        
        // Set modern column widths
        historyTable.getColumnModel().getColumn(0).setPreferredWidth(80);  // Instruction
        historyTable.getColumnModel().getColumn(1).setPreferredWidth(80);  // PC
        historyTable.getColumnModel().getColumn(2).setPreferredWidth(50);  // Flags
        for (int i = 3; i < historyColumns.length; i++) {
            historyTable.getColumnModel().getColumn(i).setPreferredWidth(75); // Registers
        }
        
        // Modern custom renderer with improved styling
        historyTable.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                Component c = super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
                
                if (isSelected) {
                    c.setBackground(new Color(51, 153, 255));
                    c.setForeground(Color.WHITE);
                } else {
                    // Check if this register changed from previous row
                    boolean changed = false;
                    if (row > 0 && column > 2) { // Skip instruction, PC, flags columns
                        Object prevValue = table.getValueAt(row - 1, column);
                        changed = !Objects.equals(value, prevValue);
                    }
                    if (changed) {
                        c.setBackground(new Color(255, 255, 180)); // Light yellow for changes
                        c.setForeground(Color.BLACK);
                    } else if (row % 2 == 0) {
                        c.setBackground(new Color(248, 248, 248)); // Alternating row colors
                        c.setForeground(Color.BLACK);
                    } else {
                        c.setBackground(Color.WHITE);
                        c.setForeground(Color.BLACK);
                    }
                }
                
                // Center align register values, left align instruction names
                if (column == 0) {
                    setHorizontalAlignment(SwingConstants.LEFT);
                } else {
                    setHorizontalAlignment(SwingConstants.CENTER);
                }
                
                return c;
            }
        });
        
        // Add modern selection listener to history table
        historyTable.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                int selectedRow = historyTable.getSelectedRow();
                if (selectedRow >= 0) {
                    // Sync with decoded table selection
                    decodedTable.setRowSelectionInterval(selectedRow, selectedRow);
                    currentInstructionRow = selectedRow;
                    updateCurrentRegisterDisplay();
                }
            }
        });
    }
    
    // Add modern context menu and enhanced features
    private void addModernHistoryTableFeatures() {
        // Add modern context menu for copy functionality
        JPopupMenu contextMenu = new JPopupMenu();
        
        JMenuItem copyCell = new JMenuItem("Copy Cell Value");
        copyCell.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
        copyCell.addActionListener(_ -> {
            int row = historyTable.getSelectedRow();
            int col = historyTable.getSelectedColumn();
            if (row >= 0 && col >= 0) {
                Object value = historyTable.getValueAt(row, col);
                if (value != null) {
                    java.awt.Toolkit.getDefaultToolkit().getSystemClipboard()
                        .setContents(new java.awt.datatransfer.StringSelection(value.toString()), null);
                }
            }
        });
        
        JMenuItem copyRow = new JMenuItem("Copy Entire Row");
        copyRow.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
        copyRow.addActionListener(_ -> {
            int row = historyTable.getSelectedRow();
            if (row >= 0) {
                StringBuilder sb = new StringBuilder();
                for (int col = 0; col < historyTable.getColumnCount(); col++) {
                    if (col > 0) sb.append("\t");
                    Object value = historyTable.getValueAt(row, col);
                    sb.append(value != null ? value.toString() : "");
                }
                java.awt.Toolkit.getDefaultToolkit().getSystemClipboard()
                    .setContents(new java.awt.datatransfer.StringSelection(sb.toString()), null);
            }
        });
        
        JMenuItem exportData = new JMenuItem("Export History...");
        exportData.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
        exportData.addActionListener(_ -> exportHistoryData());
        
        contextMenu.add(copyCell);
        contextMenu.add(copyRow);
        contextMenu.addSeparator();
        contextMenu.add(exportData);
        
        historyTable.setComponentPopupMenu(contextMenu);
        
        // Add modern keyboard shortcuts
        historyTable.getInputMap(JComponent.WHEN_FOCUSED).put(
            KeyStroke.getKeyStroke(java.awt.event.KeyEvent.VK_C, java.awt.event.InputEvent.META_DOWN_MASK), 
            "copy");
        historyTable.getActionMap().put("copy", new AbstractAction() {
            @Override
            public void actionPerformed(java.awt.event.ActionEvent e) {
                copyCell.doClick();
            }
        });
        
        // Add modern mouse hover effects
        historyTable.addMouseMotionListener(new java.awt.event.MouseMotionAdapter() {
            @Override
            public void mouseMoved(java.awt.event.MouseEvent e) {
                int row = historyTable.rowAtPoint(e.getPoint());
                if (row != historyTable.getSelectedRow()) {
                    historyTable.setToolTipText("Row " + (row + 1) + " - Click to view register state");
                }
            }
        });
    }
    
    private void exportHistoryData() {
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Export Register History");
        fileChooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter("CSV Files", "csv"));
        
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            try (java.io.PrintWriter writer = new java.io.PrintWriter(fileChooser.getSelectedFile())) {
                // Write header
                for (int col = 0; col < historyTable.getColumnCount(); col++) {
                    if (col > 0) writer.print(",");
                    writer.print("\"" + historyTable.getColumnName(col) + "\"");
                }
                writer.println();
                
                // Write data
                for (int row = 0; row < historyTable.getRowCount(); row++) {
                    for (int col = 0; col < historyTable.getColumnCount(); col++) {
                        if (col > 0) writer.print(",");
                        Object value = historyTable.getValueAt(row, col);
                        writer.print("\"" + (value != null ? value.toString() : "") + "\"");
                    }
                    writer.println();
                }
                
                JOptionPane.showMessageDialog(this, 
                    "History exported successfully to " + fileChooser.getSelectedFile().getName(),
                    "Export Complete", JOptionPane.INFORMATION_MESSAGE);
                    
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(this, 
                    "Error exporting history: " + ex.getMessage(),
                    "Export Error", JOptionPane.ERROR_MESSAGE);
            }
        }
    }
    
    private void updateCurrentRegisterDisplay() {
        if (currentInstructionRow < 0 || !instructionRegisterValues.containsKey(currentInstructionRow)) {
            for (int i = 0; i < registerLabels.length; i++) {
                if (registerLabels[i] == null) {
                    System.err.println("[WARN] registerLabels[" + i + "] is null in reset");
                    continue;
                }
                updateRegisterLabel(registerLabels[i], (i == 0 ? "PC" : i == 1 ? "FL" : "R" + (i - 2)), 0L, false);
            }
            currentRegisterPanel.revalidate();
            currentRegisterPanel.repaint();
            return;
        }
        Map<Integer, Long> regValues = instructionRegisterValues.get(currentInstructionRow);
        Set<Integer> changedRegs = instructionRegisterChanges.getOrDefault(currentInstructionRow, new HashSet<>());
        // Debug output
        System.out.println("[DEBUG] updateCurrentRegisterDisplay: row=" + currentInstructionRow);
        for (int i = 0; i < 34; i++) {
            long val = regValues.getOrDefault(i, 0L);
            System.out.println("  reg[" + i + "] = " + val);
        }
        for (int i = 0; i < 34; i++) {
            if (registerLabels[i] == null) {
                System.err.println("[WARN] registerLabels[" + i + "] is null in update");
                continue;
            }
            String name = (i == 0 ? "PC" : i == 1 ? "FL" : "R" + (i - 2));
            boolean changed = (i >= 2) ? changedRegs.contains(i - 2) : false;
            updateRegisterLabel(registerLabels[i], name, regValues.getOrDefault(i, 0L), changed);
        }
        currentRegisterPanel.revalidate();
        currentRegisterPanel.repaint();
    }
    
    private void highlightHistoryRow(int row) {
        if (row >= 0 && row < historyTable.getRowCount()) {
            historyTable.setRowSelectionInterval(row, row);
            historyTable.scrollRectToVisible(historyTable.getCellRect(row, 0, true));
        }
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // Top panel with Paste Log button
        JPanel topPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        JButton pasteLogButton = new JButton("Paste Log");
        pasteLogButton.addActionListener(_ -> showPasteLogDialog());
        topPanel.add(pasteLogButton);
        
        // Left panel: simulation log
        JPanel leftPanel = new JPanel(new BorderLayout());
        leftPanel.add(topPanel, BorderLayout.NORTH);
        leftPanel.add(new JLabel("Simulation Log:"), BorderLayout.CENTER);
        leftPanel.add(new JScrollPane(logArea), BorderLayout.SOUTH);
        
        // Right panel: decoded instructions
        JPanel decodedPanel = new JPanel(new BorderLayout());
        decodedPanel.add(new JLabel("Decoded Instructions:"), BorderLayout.NORTH);
        decodedPanel.add(new JScrollPane(decodedTable), BorderLayout.CENTER);
        
        // Bottom left: current register state (directly add currentRegisterPanel)
        // JPanel currentRegPanel = new JPanel(new BorderLayout());
        // currentRegPanel.add(currentRegisterPanel, BorderLayout.CENTER);
        
        // Bottom right: modernized history table with enhanced styling
        JPanel modernHistoryPanel = new JPanel(new BorderLayout());
        modernHistoryPanel.setBorder(BorderFactory.createTitledBorder(
            BorderFactory.createEtchedBorder(), 
            "Register History (Yellow = Changed from Previous)",
            0, 0, new Font(Font.SANS_SERIF, Font.BOLD, 12)
        ));
        
        // Create modern paging controls
        JPanel modernPagingPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        modernPagingPanel.setBackground(new Color(245, 245, 245));
        modernPagingPanel.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
        
        prevPageButton = new JButton("◀ Previous");
        nextPageButton = new JButton("Next ▶");
        pageInfoLabel = new JLabel();
        
        // Style the paging buttons
        prevPageButton.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
        nextPageButton.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
        pageInfoLabel.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 11));
        
        prevPageButton.setBackground(new Color(230, 230, 230));
        nextPageButton.setBackground(new Color(230, 230, 230));
        prevPageButton.setBorder(BorderFactory.createRaisedBevelBorder());
        nextPageButton.setBorder(BorderFactory.createRaisedBevelBorder());
        
        modernPagingPanel.add(prevPageButton);
        modernPagingPanel.add(Box.createHorizontalStrut(15));
        modernPagingPanel.add(pageInfoLabel);
        modernPagingPanel.add(Box.createHorizontalStrut(15));
        modernPagingPanel.add(nextPageButton);
        
        // Create scrollable table view
        JScrollPane modernHistoryScrollPane = new JScrollPane(historyTable);
        modernHistoryScrollPane.setPreferredSize(new Dimension(800, 250));
        modernHistoryScrollPane.getViewport().setBackground(Color.WHITE);
        modernHistoryScrollPane.setBorder(BorderFactory.createLoweredBevelBorder());
        
        modernHistoryPanel.add(modernPagingPanel, BorderLayout.NORTH);
        modernHistoryPanel.add(modernHistoryScrollPane, BorderLayout.CENTER);
        
        // Add status bar to history panel
        JLabel statusLabel = new JLabel("Ready - Select an instruction to view register changes");
        statusLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        statusLabel.setBorder(BorderFactory.createEmptyBorder(3, 10, 3, 10));
        statusLabel.setBackground(new Color(240, 240, 240));
        statusLabel.setOpaque(true);
        modernHistoryPanel.add(statusLabel, BorderLayout.SOUTH);
        
        // Create split panes
        rightSplitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT);
        rightSplitPane.setTopComponent(decodedPanel);
        rightSplitPane.setBottomComponent(currentRegisterPanel); // Use currentRegisterPanel directly
        rightSplitPane.setDividerLocation(300);
        
        bottomSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        bottomSplitPane.setLeftComponent(rightSplitPane);
        bottomSplitPane.setRightComponent(modernHistoryPanel);
        bottomSplitPane.setDividerLocation(600);
        
        // Main split pane
        mainSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, bottomSplitPane);
        mainSplitPane.setDividerLocation(400);
        mainSplitPane.setResizeWeight(0.3);
        add(mainSplitPane, BorderLayout.CENTER);
        
        prevPageButton.addActionListener(_ -> {
            if (currentPage > 0) {
                currentPage--;
                updateHistoryTable();
            }
        });
        nextPageButton.addActionListener(_ -> {
            if (currentPage < totalPages - 1) {
                currentPage++;
                updateHistoryTable();
            }
        });
    }

    // Add this method to show the paste log dialog
    private void showPasteLogDialog() {
        JTextArea pasteArea = new JTextArea(20, 80);
        pasteArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        JScrollPane scrollPane = new JScrollPane(pasteArea);
        int result = JOptionPane.showConfirmDialog(this, scrollPane, "Paste Simulation Log", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);
        if (result == JOptionPane.OK_OPTION) {
            String pastedLog = pasteArea.getText();
            if (pastedLog != null && !pastedLog.trim().isEmpty()) {
                loadContent(pastedLog);
            }
        }
    }
    
    @Override
    public void loadContent(String content) {
        logArea.setText(content);
        parseSimulationLog(content);
    }
    
    @Override
    public void saveContent() {
        // Logs are read-only
    }
    
    @Override
    public void clearContent() {
        if (logArea != null) logArea.setText("");
        if (decodedTableModel != null) decodedTableModel.setRowCount(0);
        if (historyTableModel != null) historyTableModel.setRowCount(0);

        // Only reset label values, do NOT re-initialize or null out registerLabels!
        for (int i = 0; i < 34; i++) {
            currentRegisterValues.put(i, 0L);
            if (registerLabels[i] != null) {
                String name = (i == 0) ? "PC" : (i == 1) ? "FL" : "R" + (i - 2);
                updateRegisterLabel(registerLabels[i], name, 0L, false);
            }
        }

        instructionRegisterChanges.clear();
        instructionRegisterValues.clear();
        currentInstructionRow = -1;
    }
    
    private void updateHistoryTable() {
        // Remove all rows
        historyTableModel.setRowCount(0);
        int totalRows = instructionRegisterValues.size();
        totalPages = (int) Math.ceil((double) totalRows / rowsPerPage);
        if (totalPages == 0) totalPages = 1;
        if (currentPage >= totalPages) currentPage = totalPages - 1;
        int start = currentPage * rowsPerPage;
        int end = Math.min(start + rowsPerPage, totalRows);
        for (int i = start; i < end; i++) {
            Map<Integer, Long> regSnapshot = instructionRegisterValues.get(i);
            // Note: changedRegs preserved for future functionality
            Object[] historyRow = new Object[36];
            historyRow[0] = decodedTableModel.getRowCount() > i ? decodedTableModel.getValueAt(i, 2) : "";
            historyRow[1] = regSnapshot != null ? String.format("0x%08X", regSnapshot.getOrDefault(0, 0L)) : "";
            historyRow[2] = regSnapshot != null ? regSnapshot.getOrDefault(1, 0L).toString() : "";
            for (int j = 0; j < 32; j++) {
                historyRow[j + 3] = regSnapshot != null ? String.format("0x%08X", regSnapshot.getOrDefault(j + 2, 0L)) : "";
            }
            historyTableModel.addRow(historyRow);
        }
        pageInfoLabel.setText("Page " + (currentPage + 1) + " of " + totalPages);
        prevPageButton.setEnabled(currentPage > 0);
        nextPageButton.setEnabled(currentPage < totalPages - 1);
        // After updating table/page, update register display for selected row
        if (decodedTable.getSelectedRow() >= 0) {
            currentInstructionRow = decodedTable.getSelectedRow();
            updateCurrentRegisterDisplay();
            currentRegisterPanel.revalidate();
            currentRegisterPanel.repaint();
        }
    }
    
    private void parseSimulationLog(String content) {
        decodedTableModel.setRowCount(0);
        historyTableModel.setRowCount(0);
        instructionRegisterChanges.clear();
        instructionRegisterValues.clear();
        String[] lines = content.split("\n");
        
        // Patterns for parsing simulation log
        Pattern executePattern = Pattern.compile("DEBUG CPU Execute: PC=(0x[0-9A-Fa-f]+), Opcode=([0-9A-Fa-f]+), rd=\\s*(\\d+), rs1=\\s*(\\d+), rs2=\\s*(\\d+), imm=([0-9A-Fa-f]+)");
        Pattern writebackPattern = Pattern.compile("DEBUG CPU Writeback: Writing\\s+(\\d+) to R (\\d+)");
        Pattern flagsPattern = Pattern.compile("DEBUG CPU: Flags updated to C=(\\d+) Z=(\\d+) N=(\\d+) V=(\\d+)");
        Pattern regfileWritePattern = Pattern.compile("\\[register_file] Write: R(\\d+) <= 0x([0-9A-Fa-f]{8})");
        
        List<InstructionInfo> instructions = new ArrayList<>();
        Map<Integer, Long> regValues = new HashMap<>();
        for (int i = 0; i < 34; i++) regValues.put(i, 0L);
        String lastFlags = "0000";
        
        InstructionInfo currentInstruction = null;
        
        for (String origLine : lines) {
            String line = stripLogPrefix(origLine);
            
            // Parse instruction execution
            Matcher executeMatcher = executePattern.matcher(line);
            if (executeMatcher.find()) {
                // Save previous instruction if it exists
                if (currentInstruction != null) {
                    currentInstruction.finalizeRegisters(regValues, lastFlags);
                    instructions.add(currentInstruction);
                }
                
                // Start new instruction
                String pc = executeMatcher.group(1);
                int opcode = Integer.parseInt(executeMatcher.group(2), 16);
                int rd = Integer.parseInt(executeMatcher.group(3));
                int rs1 = Integer.parseInt(executeMatcher.group(4));
                int rs2 = Integer.parseInt(executeMatcher.group(5));
                String immStr = executeMatcher.group(6);
                int imm = 0;
                try {
                    imm = Integer.parseInt(immStr, 16);
                    if (imm > 0x7F) {
                        imm = imm - 0x100;
                    }
                } catch (NumberFormatException e) {
                    imm = 0;
                }
                
                currentInstruction = new InstructionInfo(pc, opcode, rd, rs1, rs2, imm);
                continue;
            }
            
            // Parse register writeback
            Matcher writebackMatcher = writebackPattern.matcher(line);
            if (writebackMatcher.find()) {
                try {
                    long value = Long.parseLong(writebackMatcher.group(1));
                    int regNum = Integer.parseInt(writebackMatcher.group(2));
                    if (regNum >= 0 && regNum < 32) {
                        regValues.put(regNum + 2, value);
                        if (currentInstruction != null) {
                            currentInstruction.changedRegisters.add(regNum);
                        }
                    }
                } catch (NumberFormatException e) {
                    continue;
                }
            }
            
            // Parse flags update
            Matcher flagsMatcher = flagsPattern.matcher(line);
            if (flagsMatcher.find()) {
                String c = flagsMatcher.group(1);
                String z = flagsMatcher.group(2);
                String n = flagsMatcher.group(3);
                String v = flagsMatcher.group(4);
                lastFlags = c + z + n + v;
                regValues.put(1, Long.parseLong(lastFlags));
            }
            
            // Parse register_file write
            Matcher regfileWriteMatcher = regfileWritePattern.matcher(line);
            if (regfileWriteMatcher.find()) {
                int regNum = Integer.parseInt(regfileWriteMatcher.group(1));
                long value = Long.parseLong(regfileWriteMatcher.group(2), 16);
                if (regNum >= 0 && regNum < 32) {
                    regValues.put(regNum + 2, value);
                    if (currentInstruction != null) {
                        currentInstruction.changedRegisters.add(regNum);
                    }
                }
            }
        }
        
        // Save the last instruction
        if (currentInstruction != null) {
            currentInstruction.finalizeRegisters(regValues, lastFlags);
            instructions.add(currentInstruction);
        }
        
        // Now populate the tables with the collected instruction info
        int instructionCount = 0;
        for (InstructionInfo inst : instructions) {
            // Add to decoded table
            Object[] row = InstructionDecoder.decodeFromSimLog(inst.pc, inst.opcode, inst.rd, inst.rs1, inst.rs2, inst.imm);
            decodedTableModel.addRow(row);
            
            // Store register tracking info
            instructionRegisterChanges.put(instructionCount, new HashSet<>(inst.changedRegisters));
            instructionRegisterValues.put(instructionCount, new HashMap<>(inst.registerSnapshot));
            
            // Add to history table
            Object[] historyRow = new Object[36];
            historyRow[0] = row[2]; // Mnemonic as instruction
            historyRow[1] = inst.pc;
            historyRow[2] = inst.flags;
            for (int i = 0; i < 32; i++) {
                historyRow[i + 3] = String.format("0x%08X", (int)(long)inst.registerSnapshot.getOrDefault(i + 2, 0L));
            }
            historyRow[35] = String.format("Inst %d", instructionCount);
            historyTableModel.addRow(historyRow);
            
            instructionCount++;
        }
        
        currentPage = 0;
        updateHistoryTable();
        if (decodedTable.getRowCount() > 0) {
            decodedTable.setRowSelectionInterval(0, 0);
            currentInstructionRow = 0;
            updateCurrentRegisterDisplay();
            currentRegisterPanel.revalidate();
            currentRegisterPanel.repaint();
        }
        updateStatus("Parsed " + instructionCount + " instructions from simulation log");
    }
    
    // Helper class to track instruction information
    private static class InstructionInfo {
        String pc;
        int opcode, rd, rs1, rs2, imm;
        Set<Integer> changedRegisters = new HashSet<>();
        Map<Integer, Long> registerSnapshot;
        String flags;
        
        InstructionInfo(String pc, int opcode, int rd, int rs1, int rs2, int imm) {
            this.pc = pc;
            this.opcode = opcode;
            this.rd = rd;
            this.rs1 = rs1;
            this.rs2 = rs2;
            this.imm = imm;
        }
        
        void finalizeRegisters(Map<Integer, Long> regValues, String flags) {
            this.registerSnapshot = new HashMap<>(regValues);
            this.registerSnapshot.put(0, Long.decode(pc)); // PC
            this.registerSnapshot.put(1, Long.parseLong(flags)); // Flags
            this.flags = flags;
        }
    }
    
    private String stripLogPrefix(String line) {
        // Remove SIM:, M:, or any prefix ending with ':' and whitespace
        return line.replaceFirst("^(SIM:|M:|[A-Z]+:)\\s*", "").trim();
    }
}
