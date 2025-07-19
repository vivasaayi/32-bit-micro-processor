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
import java.util.Arrays;

public class SimulationLogTab extends BaseTab {
    private JTextArea logArea;
    private JTable decodedTable;
    private DefaultTableModel decodedTableModel;
    private JPanel currentRegisterPanel;
    private JTable historyTable;
    private DefaultTableModel historyTableModel;
    
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
        // System.out.println("Length of JLables:" + registerLabels.length);
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
        String[] decodedColumns = {"PC", "OpCode", "Mnemonic", "RD", "RS1", "RS2", "IMM", "Description", "Instruction Set"};
        decodedTableModel = new DefaultTableModel(decodedColumns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        decodedTable = new JTable(decodedTableModel);
        // Add listener for instruction selection to show details
        decodedTable.getSelectionModel().addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting()) {
                int selectedRow = decodedTable.getSelectedRow();
                if (selectedRow >= 0) {
                    showInstructionDetails(selectedRow);
                    currentInstructionRow = selectedRow;
                    updateCurrentRegisterDisplay();
                }
            }
        });
        
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
            // System.out.println("Creating label for register: " + registerNames[i]);
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
        // System.out.println("Update Register label called");
        // System.out.println(label);
        // System.out.println(name);
        // System.out.println(value);
        // System.out.println(changed);

        if (label == null) return;
        int intValue = (int) value;
        String hex = String.format("0x%08X", intValue);
        String binary = String.format("%32s", Integer.toBinaryString(intValue)).replace(' ', '0');
        String decimal = String.valueOf(intValue);
        // Plain text, 4 lines: name, hex, binary, decimal
        String text = name + "\n" + hex + "\n" + binary + "\n" + decimal;
        // System.out.println(text);
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
        historyTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10)); // Smaller font
        historyTable.setRowHeight(20);
        historyTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        historyTable.setAutoResizeMode(JTable.AUTO_RESIZE_OFF); // Allow horizontal scroll
        historyTable.getTableHeader().setFont(new Font(Font.MONOSPACED, Font.BOLD, 10));
        historyTable.getTableHeader().setBackground(new Color(240, 240, 240));
        
        // Set wider column widths for full value display
        historyTable.getColumnModel().getColumn(0).setPreferredWidth(90);  // Instruction
        historyTable.getColumnModel().getColumn(1).setPreferredWidth(110); // PC
        historyTable.getColumnModel().getColumn(2).setPreferredWidth(60);  // Flags
        for (int i = 3; i < historyColumns.length; i++) {
            historyTable.getColumnModel().getColumn(i).setPreferredWidth(120); // Registers
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
        
        // Add tooltips for full cell values
        historyTable.addMouseMotionListener(new java.awt.event.MouseMotionAdapter() {
            public void mouseMoved(java.awt.event.MouseEvent e) {
                int row = historyTable.rowAtPoint(e.getPoint());
                int col = historyTable.columnAtPoint(e.getPoint());
                if (row >= 0 && col >= 0) {
                    Object value = historyTable.getValueAt(row, col);
                    historyTable.setToolTipText(value != null ? value.toString() : null);
                }
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

        // Create enhanced collapsible panels for modern UX
        CollapsiblePanel logPanel = createLogPanel();
        CollapsiblePanel instructionsPanel = createInstructionsPanel();
        CollapsiblePanel registerPanel = createRegisterPanel();
        CollapsiblePanel historyPanel = createHistoryPanel();

        // Store panel references for smart management
        this.logPanel = logPanel;
        this.instructionsPanel = instructionsPanel;
        this.registerPanel = registerPanel;
        this.historyPanel = historyPanel;

        // Use JSplitPane with improved behavior
        JSplitPane split1 = new JSplitPane(JSplitPane.VERTICAL_SPLIT, logPanel, instructionsPanel);
        split1.setResizeWeight(0.25);
        split1.setOneTouchExpandable(true);
        split1.setContinuousLayout(true);
        split1.setBorder(null); // Remove default border for cleaner look
        
        JSplitPane split2 = new JSplitPane(JSplitPane.VERTICAL_SPLIT, split1, registerPanel);
        split2.setResizeWeight(0.5);
        split2.setOneTouchExpandable(true);
        split2.setContinuousLayout(true);
        split2.setBorder(null);
        
        JSplitPane split3 = new JSplitPane(JSplitPane.VERTICAL_SPLIT, split2, historyPanel);
        split3.setResizeWeight(0.75);
        split3.setOneTouchExpandable(true);
        split3.setContinuousLayout(true);
        split3.setBorder(null);

        // Enhanced top panel with modern controls
        JPanel controlPanel = createEnhancedControlPanel(logPanel, instructionsPanel, registerPanel, historyPanel);

        add(controlPanel, BorderLayout.NORTH);
        add(split3, BorderLayout.CENTER);
        
        // Add keyboard shortcuts
        setupKeyboardShortcuts();
    }
    
    // Add fields to store panel references
    private CollapsiblePanel logPanel;
    private CollapsiblePanel instructionsPanel;
    private CollapsiblePanel registerPanel;
    private CollapsiblePanel historyPanel;
    
    private JPanel createEnhancedControlPanel(CollapsiblePanel... panels) {
        JPanel mainControlPanel = new JPanel(new BorderLayout());
        mainControlPanel.setBackground(new Color(250, 250, 250));
        mainControlPanel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createMatteBorder(0, 0, 1, 0, new Color(200, 200, 200)),
            BorderFactory.createEmptyBorder(8, 12, 8, 12)
        ));

        // Left side - Main actions
        JPanel leftPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 8, 0));
        leftPanel.setOpaque(false);

        JButton pasteLogButton = createStyledButton("📋 Paste Log", "Paste simulation log from clipboard", Color.BLUE);
        pasteLogButton.addActionListener(_ -> showPasteLogDialog());

        JButton loadConsoleButton = createStyledButton("📂 Load Console Log", "Load log from simulation console", new Color(0, 150, 0));
        loadConsoleButton.addActionListener(_ -> {
            String consoleText = logArea.getText();
            if (consoleText == null || consoleText.trim().isEmpty()) {
                showWarningDialog("No Log", "Simulation log is empty. Please paste or run a simulation first.");
            } else {
                loadContent(consoleText);
                smartExpandPanels(); // Auto-expand relevant panels
            }
        });

        JButton clearAllButton = createStyledButton("🗑️ Clear All", "Clear all simulation data", new Color(200, 50, 50));
        clearAllButton.addActionListener(_ -> {
            if (showConfirmDialog("Clear All Data", "Are you sure you want to clear all simulation data?")) {
                clearContent();
                collapseAllPanels();
            }
        });

        leftPanel.add(pasteLogButton);
        leftPanel.add(loadConsoleButton);
        leftPanel.add(Box.createHorizontalStrut(8));
        leftPanel.add(clearAllButton);

        // Center - Panel management
        JPanel centerPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 6, 0));
        centerPanel.setOpaque(false);

        JButton expandAllButton = createStyledButton("⬇️ Expand All", "Expand all panels", new Color(70, 130, 180));
        JButton collapseAllButton = createStyledButton("⬆️ Collapse All", "Collapse all panels", new Color(100, 100, 100));
        JButton autoLayoutButton = createStyledButton("🎯 Smart Layout", "Automatically arrange panels based on content", new Color(150, 100, 200));

        expandAllButton.addActionListener(_ -> expandAllPanels());
        collapseAllButton.addActionListener(_ -> collapseAllPanels());
        autoLayoutButton.addActionListener(_ -> smartExpandPanels());

        centerPanel.add(expandAllButton);
        centerPanel.add(collapseAllButton);
        centerPanel.add(autoLayoutButton);

        // Right side - Info and settings
        JPanel rightPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 6, 0));
        rightPanel.setOpaque(false);

        JLabel statusLabel = new JLabel("Ready");
        statusLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 11));
        statusLabel.setForeground(new Color(100, 100, 100));
        this.statusLabel = statusLabel; // Store reference

        JButton helpButton = createStyledButton("❓", "Show keyboard shortcuts and help", new Color(150, 150, 150));
        helpButton.addActionListener(_ -> showHelpDialog());

        rightPanel.add(statusLabel);
        rightPanel.add(Box.createHorizontalStrut(8));
        rightPanel.add(helpButton);

        mainControlPanel.add(leftPanel, BorderLayout.WEST);
        mainControlPanel.add(centerPanel, BorderLayout.CENTER);
        mainControlPanel.add(rightPanel, BorderLayout.EAST);

        return mainControlPanel;
    }
    
    private JLabel statusLabel; // Add field for status updates
    
    private JButton createStyledButton(String text, String tooltip, Color accentColor) {
        JButton button = new JButton(text);
        button.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 11));
        button.setToolTipText(tooltip);
        button.setFocusPainted(false);
        button.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(accentColor.darker(), 1),
            BorderFactory.createEmptyBorder(6, 12, 6, 12)
        ));
        button.setBackground(new Color(accentColor.getRed(), accentColor.getGreen(), accentColor.getBlue(), 20));
        button.setForeground(accentColor.darker());
        
        // Add hover effects
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mouseEntered(java.awt.event.MouseEvent e) {
                button.setBackground(new Color(accentColor.getRed(), accentColor.getGreen(), accentColor.getBlue(), 40));
            }
            
            @Override
            public void mouseExited(java.awt.event.MouseEvent e) {
                button.setBackground(new Color(accentColor.getRed(), accentColor.getGreen(), accentColor.getBlue(), 20));
            }
        });
        
        return button;
    }
    
    private void setupKeyboardShortcuts() {
        // Add keyboard shortcuts using InputMap and ActionMap
        getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke("ctrl E"), "expandAll");
        getActionMap().put("expandAll", new AbstractAction() {
            @Override
            public void actionPerformed(java.awt.event.ActionEvent e) {
                expandAllPanels();
            }
        });
        
        getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke("ctrl C"), "collapseAll");
        getActionMap().put("collapseAll", new AbstractAction() {
            @Override
            public void actionPerformed(java.awt.event.ActionEvent e) {
                collapseAllPanels();
            }
        });
        
        getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke("ctrl L"), "smartLayout");
        getActionMap().put("smartLayout", new AbstractAction() {
            @Override
            public void actionPerformed(java.awt.event.ActionEvent e) {
                smartExpandPanels();
            }
        });
        
        getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke("F1"), "showHelp");
        getActionMap().put("showHelp", new AbstractAction() {
            @Override
            public void actionPerformed(java.awt.event.ActionEvent e) {
                showHelpDialog();
            }
        });
    }
    
    private void expandAllPanels() {
        if (logPanel != null) logPanel.setExpanded(true);
        if (instructionsPanel != null) instructionsPanel.setExpanded(true);
        if (registerPanel != null) registerPanel.setExpanded(true);
        if (historyPanel != null) historyPanel.setExpanded(true);
        updateStatus("All panels expanded");
        forceLayoutUpdate();
    }
    
    private void collapseAllPanels() {
        if (logPanel != null) logPanel.setExpanded(false);
        if (instructionsPanel != null) instructionsPanel.setExpanded(false);
        if (registerPanel != null) registerPanel.setExpanded(false);
        if (historyPanel != null) historyPanel.setExpanded(false);
        updateStatus("All panels collapsed");
        forceLayoutUpdate();
    }
    
    private void smartExpandPanels() {
        // Smart expansion based on content availability
        boolean hasLog = logArea.getText() != null && !logArea.getText().trim().isEmpty();
        boolean hasInstructions = decodedTableModel.getRowCount() > 0;
        boolean hasRegisterData = currentRegisterValues != null && !currentRegisterValues.isEmpty();
        boolean hasHistory = historyTableModel.getRowCount() > 0;
        
        if (logPanel != null) logPanel.setExpanded(hasLog);
        if (instructionsPanel != null) instructionsPanel.setExpanded(hasInstructions);
        if (registerPanel != null) registerPanel.setExpanded(hasRegisterData);
        if (historyPanel != null) historyPanel.setExpanded(hasHistory);
        
        // Update panel titles with data indicators
        updatePanelTitles(hasLog, hasInstructions, hasRegisterData, hasHistory);
        updateStatus("Smart layout applied");
        forceLayoutUpdate();
    }
    
    private void updatePanelTitles(boolean hasLog, boolean hasInstructions, boolean hasRegisterData, boolean hasHistory) {
        if (logPanel != null) {
            String title = "📜 Simulation Log" + (hasLog ? " ✓" : " ⚪");
            logPanel.updateTitle(title);
        }
        if (instructionsPanel != null) {
            String title = "🔍 Decoded Instructions" + (hasInstructions ? " ✓ (" + decodedTableModel.getRowCount() + ")" : " ⚪");
            instructionsPanel.updateTitle(title);
        }
        if (registerPanel != null) {
            String title = "📊 Current Register State" + (hasRegisterData ? " ✓" : " ⚪");
            registerPanel.updateTitle(title);
        }
        if (historyPanel != null) {
            String title = "📈 Register History" + (hasHistory ? " ✓ (" + historyTableModel.getRowCount() + ")" : " ⚪");
            historyPanel.updateTitle(title);
        }
    }
    
    protected void updateStatus(String message) {
        if (statusLabel != null) {
            statusLabel.setText(message);
            // Clear status after 3 seconds using javax.swing.Timer
            javax.swing.Timer swingTimer = new javax.swing.Timer(3000, _ -> {
                if (statusLabel != null) statusLabel.setText("Ready");
            });
            swingTimer.setRepeats(false);
            swingTimer.start();
        }
    }
    
    private void forceLayoutUpdate() {
        SwingUtilities.invokeLater(() -> {
            revalidate();
            repaint();
            Container parent = getParent();
            while (parent != null) {
                if (parent instanceof JSplitPane) {
                    ((JSplitPane) parent).resetToPreferredSizes();
                }
                parent.revalidate();
                parent.repaint();
                parent = parent.getParent();
            }
        });
    }
    
    private void showHelpDialog() {
        String helpText = """
            Simulation Log Tab - Keyboard Shortcuts:
            
            Ctrl+E    - Expand all panels
            Ctrl+C    - Collapse all panels  
            Ctrl+L    - Smart layout (auto-arrange based on content)
            F1        - Show this help
            
            Panel Features:
            • Click panel headers to expand/collapse
            • Panels auto-expand when new data is loaded
            • Status indicators show data availability (✓/⚪)
            • Right-click tables for copy/export options
            
            Navigation:
            • Select instruction in decoded table to view register state
            • Register history shows changes after each instruction
            • Use pagination controls for large datasets
            """;
            
        JTextArea textArea = new JTextArea(helpText);
        textArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        textArea.setEditable(false);
        textArea.setBackground(new Color(250, 250, 250));
        
        JScrollPane scrollPane = new JScrollPane(textArea);
        scrollPane.setPreferredSize(new Dimension(500, 300));
        
        JOptionPane.showMessageDialog(this, scrollPane, "Help - Simulation Log Tab", JOptionPane.INFORMATION_MESSAGE);
    }
    
    private void showWarningDialog(String title, String message) {
        JOptionPane.showMessageDialog(this, message, title, JOptionPane.WARNING_MESSAGE);
    }
    
    private boolean showConfirmDialog(String title, String message) {
        return JOptionPane.showConfirmDialog(this, message, title, JOptionPane.YES_NO_OPTION) == JOptionPane.YES_OPTION;
    }
    
    private CollapsiblePanel createLogPanel() {
        JPanel logContent = new JPanel(new BorderLayout());
        logContent.add(new JLabel("Simulation Log:"), BorderLayout.NORTH);
        logContent.add(new JScrollPane(logArea), BorderLayout.CENTER);
        
        CollapsiblePanel panel = new CollapsiblePanel("📜 Simulation Log", logContent, true);
        panel.setPreferredSize(new Dimension(0, 200));
        return panel;
    }
    
    private CollapsiblePanel createInstructionsPanel() {
        JPanel instructionsContent = new JPanel(new BorderLayout());
        instructionsContent.add(new JLabel("Decoded Instructions:"), BorderLayout.NORTH);
        instructionsContent.add(new JScrollPane(decodedTable), BorderLayout.CENTER);
        
        CollapsiblePanel panel = new CollapsiblePanel("🔍 Decoded Instructions", instructionsContent, true);
        panel.setPreferredSize(new Dimension(0, 200));
        return panel;
    }
    
    private CollapsiblePanel createRegisterPanel() {
        JPanel registerContent = new JPanel(new BorderLayout());
        registerContent.add(currentRegisterPanel, BorderLayout.CENTER);
        
        CollapsiblePanel panel = new CollapsiblePanel("📊 Current Register State", registerContent, true);
        panel.setPreferredSize(new Dimension(0, 250));
        return panel;
    }
    
    private CollapsiblePanel createHistoryPanel() {
        // Reuse the modern history panel we created earlier
        JPanel modernHistoryPanel = new JPanel(new BorderLayout());
        
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
        
        modernPagingPanel.add(prevPageButton);
        modernPagingPanel.add(Box.createHorizontalStrut(15));
        modernPagingPanel.add(pageInfoLabel);
        modernPagingPanel.add(Box.createHorizontalStrut(15));
        modernPagingPanel.add(nextPageButton);
        
        // Create scrollable table view
        JScrollPane modernHistoryScrollPane = new JScrollPane(historyTable);
        modernHistoryScrollPane.setPreferredSize(new Dimension(800, 200));
        modernHistoryScrollPane.getViewport().setBackground(Color.WHITE);
        
        modernHistoryPanel.add(modernPagingPanel, BorderLayout.NORTH);
        modernHistoryPanel.add(modernHistoryScrollPane, BorderLayout.CENTER);
        
        // Action listeners for paging
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
        
        CollapsiblePanel panel = new CollapsiblePanel("📈 Register History", modernHistoryPanel, true);
        panel.setPreferredSize(new Dimension(0, 300));
        return panel;
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
        // Immediately update the text area
        logArea.setText(content);
        updateStatus("Loading simulation log...");
        
        // Parse the log in a background thread to avoid blocking UI
        SwingWorker<Void, Void> parser = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() throws Exception {
                parseSimulationLog(content);
                return null;
            }
            
            @Override
            protected void done() {
                // Auto-apply smart layout when parsing is complete
                SwingUtilities.invokeLater(() -> {
                    smartExpandPanels();
                    updateStatus("Simulation log loaded and parsed");
                });
            }
        };
        parser.execute();
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
        
        // Update panel titles to show empty state and status
        updatePanelTitles(false, false, false, false);
        updateStatus("All content cleared");
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
        
        // Enhanced patterns for parsing simulation log with clear markers
        Pattern instrStartPattern = Pattern.compile("==== INSTR_START ==== PC=(0x[0-9A-Fa-f]+) IS=(0x[0-9A-Fa-f]+) ====");
        Pattern instrEndPattern = Pattern.compile("==== INSTR_END ==== PC=(0x[0-9A-Fa-f]+) ====");
        Pattern decodeFieldsPattern = Pattern.compile("DECODE_FIELDS: Opcode=(0x[0-9A-Fa-f]+), rd=(\\d+), rs1=(\\d+), rs2=(\\d+), imm=(0x[0-9A-Fa-f]+)");
        Pattern writebackRegPattern = Pattern.compile("WRITEBACK_REG: R(\\d+) <= (0x[0-9A-Fa-f]+)");
        Pattern registerFileWritePattern = Pattern.compile("REGISTER_FILE_WRITE: R(\\d+) <= (0x[0-9A-Fa-f]+)");
        Pattern executeFlagsAfterPattern = Pattern.compile("EXECUTE_FLAGS_AFTER: C=(\\d+) Z=(\\d+) N=(\\d+) V=(\\d+)");
        
        List<InstructionInfo> instructions = new ArrayList<>();
        Map<Integer, Long> regValues = new HashMap<>();
        for (int i = 0; i < 34; i++) regValues.put(i, 0L);
        String lastFlags = "0000";
        
        InstructionInfo currentInstruction = null;
        List<String> currentInstructionLogs = new ArrayList<>();
        
        // Multi-pass parsing approach using clear instruction markers
        for (String origLine : lines) {
            String line = stripLogPrefix(origLine);
            
            // Check for instruction start marker
            Matcher instrStartMatcher = instrStartPattern.matcher(line);
            if (instrStartMatcher.find()) {
                // Save previous instruction if it exists
                if (currentInstruction != null) {
                    currentInstruction.logs = new ArrayList<>(currentInstructionLogs);
                    currentInstruction.finalizeRegisters(regValues, lastFlags);
                    instructions.add(currentInstruction);
                }
                
                // Start new instruction
                String pc = instrStartMatcher.group(1);
                String instructionSet = instrStartMatcher.group(2);
                currentInstruction = new InstructionInfo(pc, 0, 0, 0, 0, 0);
                currentInstruction.instructionSet = instructionSet;
                currentInstructionLogs.clear();
                currentInstructionLogs.add(origLine);
                continue;
            }
            
            // Check for instruction end marker
            Matcher instrEndMatcher = instrEndPattern.matcher(line);
            if (instrEndMatcher.find()) {
                if (currentInstruction != null) {
                    currentInstructionLogs.add(origLine);
                }
                continue;
            }
            
            // If we're currently processing an instruction, collect all logs
            if (currentInstruction != null) {
                currentInstructionLogs.add(origLine);
                
                // Parse decode fields
                Matcher decodeFieldsMatcher = decodeFieldsPattern.matcher(line);
                if (decodeFieldsMatcher.find()) {
                    currentInstruction.opcode = Integer.parseInt(decodeFieldsMatcher.group(1).substring(2), 16);
                    currentInstruction.rd = Integer.parseInt(decodeFieldsMatcher.group(2));
                    currentInstruction.rs1 = Integer.parseInt(decodeFieldsMatcher.group(3));
                    currentInstruction.rs2 = Integer.parseInt(decodeFieldsMatcher.group(4));
                    currentInstruction.imm = Integer.parseInt(decodeFieldsMatcher.group(5).substring(2), 16);
                    // Convert to signed if needed
                    if (currentInstruction.imm > 0x7FFFFFFF) {
                        currentInstruction.imm = (int)(currentInstruction.imm - 0x100000000L);
                    }
                }
                
                // Parse flags after execution
                Matcher executeFlagsAfterMatcher = executeFlagsAfterPattern.matcher(line);
                if (executeFlagsAfterMatcher.find()) {
                    String c = executeFlagsAfterMatcher.group(1);
                    String z = executeFlagsAfterMatcher.group(2);
                    String n = executeFlagsAfterMatcher.group(3);
                    String v = executeFlagsAfterMatcher.group(4);
                    lastFlags = c + z + n + v;
                    regValues.put(1, Long.parseLong(lastFlags));
                }
                
                // Parse register writes
                Matcher writebackRegMatcher = writebackRegPattern.matcher(line);
                if (writebackRegMatcher.find()) {
                    int regNum = Integer.parseInt(writebackRegMatcher.group(1));
                    long value = Long.parseLong(writebackRegMatcher.group(2).substring(2), 16);
                    if (regNum >= 0 && regNum < 32) {
                        regValues.put(regNum + 2, value);
                        currentInstruction.changedRegisters.add(regNum);
                    }
                }
                
                // Parse register file writes
                Matcher registerFileWriteMatcher = registerFileWritePattern.matcher(line);
                if (registerFileWriteMatcher.find()) {
                    int regNum = Integer.parseInt(registerFileWriteMatcher.group(1));
                    long value = Long.parseLong(registerFileWriteMatcher.group(2).substring(2), 16);
                    if (regNum >= 0 && regNum < 32) {
                        regValues.put(regNum + 2, value);
                        currentInstruction.changedRegisters.add(regNum);
                    }
                }
            }
        }
        
        // Save the last instruction
        if (currentInstruction != null) {
            currentInstruction.logs = new ArrayList<>(currentInstructionLogs);
            currentInstruction.finalizeRegisters(regValues, lastFlags);
            instructions.add(currentInstruction);
        }
        
        // Now populate the tables with the collected instruction info
        int instructionCount = 0;
        for (InstructionInfo inst : instructions) {
            // Use the instruction set (IS) for accurate decoding instead of parsed fields
            Object[] row;
            if (inst.instructionSet != null && !inst.instructionSet.isEmpty()) {
                // Decode using the raw instruction word for maximum accuracy
                long instructionWord = Long.parseLong(inst.instructionSet.substring(2), 16);
                row = InstructionDecoder.decodeFromInstructionWord(inst.pc, instructionWord);
            } else {
                // Fallback to parsed fields if IS not available
                row = InstructionDecoder.decodeFromSimLog(inst.pc, inst.opcode, inst.rd, inst.rs1, inst.rs2, inst.imm);
            }
            
            // Add instruction set to the row
            Object[] newRow = Arrays.copyOf(row, row.length + 1);
            newRow[row.length] = inst.instructionSet != null ? inst.instructionSet : "N/A";
            decodedTableModel.addRow(newRow);
            
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
        
        // Store parsed instructions for the details window
        parsedInstructions.clear();
        parsedInstructions.addAll(instructions);
        
        updateStatus("Parsed " + instructions.size() + " instructions using enhanced multi-pass parsing with instruction markers");
    }
    private JFrame instructionDetailsFrame = null;
    private JTextArea instructionLogsArea;
    private JTable instructionDetailsTable;
    
    private void showInstructionDetails(int instructionIndex) {
        // Create or update instruction details window
        if (instructionDetailsFrame == null) {
            createInstructionDetailsWindow();
        }
        
        // Update details for the selected instruction
        updateInstructionDetailsWindow(instructionIndex);
        
        // Show window if hidden - without stealing focus
        if (!instructionDetailsFrame.isVisible()) {
            instructionDetailsFrame.setVisible(true);
        }
        
        // Bring to front but don't request focus
        instructionDetailsFrame.toFront();
        instructionDetailsFrame.repaint();
    }
    
    private void createInstructionDetailsWindow() {
        instructionDetailsFrame = new JFrame("Instruction Details - Detachable Debug Panel");
        instructionDetailsFrame.setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);
        instructionDetailsFrame.setSize(800, 600);
        instructionDetailsFrame.setLocationRelativeTo(this);
        
        // Prevent the window from stealing focus
        instructionDetailsFrame.setFocusableWindowState(false);
        instructionDetailsFrame.setAutoRequestFocus(false);
        
        JPanel mainPanel = new JPanel(new BorderLayout());
        
        // Top panel with instruction summary
        JPanel summaryPanel = new JPanel(new BorderLayout());
        summaryPanel.setBorder(BorderFactory.createTitledBorder("Instruction Summary"));
        
        String[] detailColumns = {"Field", "Value", "Description"};
        DefaultTableModel detailModel = new DefaultTableModel(detailColumns, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        instructionDetailsTable = new JTable(detailModel);
        instructionDetailsTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        summaryPanel.add(new JScrollPane(instructionDetailsTable), BorderLayout.CENTER);
        
        // Bottom panel with raw logs
        JPanel logsPanel = new JPanel(new BorderLayout());
        logsPanel.setBorder(BorderFactory.createTitledBorder("Raw Logs for this Instruction"));
        
        instructionLogsArea = new JTextArea();
        instructionLogsArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        instructionLogsArea.setEditable(false);
        instructionLogsArea.setBackground(new Color(248, 248, 248));
        logsPanel.add(new JScrollPane(instructionLogsArea), BorderLayout.CENTER);
        
        // Split the window
        JSplitPane splitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, summaryPanel, logsPanel);
        splitPane.setResizeWeight(0.4);
        splitPane.setOneTouchExpandable(true);
        
        mainPanel.add(splitPane, BorderLayout.CENTER);
        
        // Add a close button and detach info
        JPanel buttonPanel = new JPanel(new FlowLayout());
        
        JButton focusButton = new JButton("Focus Window");
        focusButton.addActionListener(e -> {
            instructionDetailsFrame.setFocusableWindowState(true);
            instructionDetailsFrame.requestFocus();
            instructionDetailsFrame.toFront();
        });
        
        JButton closeButton = new JButton("Close");
        closeButton.addActionListener(e -> instructionDetailsFrame.setVisible(false));
        
        JLabel infoLabel = new JLabel("This window can be moved to another monitor for multi-screen debugging");
        infoLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        
        buttonPanel.add(infoLabel);
        buttonPanel.add(focusButton);
        buttonPanel.add(closeButton);
        
        mainPanel.add(buttonPanel, BorderLayout.SOUTH);
        instructionDetailsFrame.add(mainPanel);
    }
    
    private void updateInstructionDetailsWindow(int instructionIndex) {
        if (instructionDetailsFrame == null || instructionDetailsTable == null) return;
        
        DefaultTableModel model = (DefaultTableModel) instructionDetailsTable.getModel();
        model.setRowCount(0);
        
        // Get instruction details from the decoded table
        if (instructionIndex >= 0 && instructionIndex < decodedTableModel.getRowCount()) {
            Object[] rowData = new Object[decodedTableModel.getColumnCount()];
            for (int i = 0; i < decodedTableModel.getColumnCount(); i++) {
                rowData[i] = decodedTableModel.getValueAt(instructionIndex, i);
            }
            
            // Add details to the table
            model.addRow(new Object[]{"PC", rowData[0], "Program Counter"});
            model.addRow(new Object[]{"OpCode", rowData[1], "Operation Code"});
            model.addRow(new Object[]{"Mnemonic", rowData[2], "Instruction Name"});
            model.addRow(new Object[]{"RD", rowData[3], "Destination Register"});
            model.addRow(new Object[]{"RS1", rowData[4], "Source Register 1"});
            model.addRow(new Object[]{"RS2", rowData[5], "Source Register 2"});
            model.addRow(new Object[]{"IMM", rowData[6], "Immediate Value"});
            model.addRow(new Object[]{"Description", rowData[7], "Operation Description"});
            if (rowData.length > 8) {
                model.addRow(new Object[]{"Instruction Set", rowData[8], "Raw 32-bit Instruction Word"});
            }
            
            // Add register state information
            if (instructionRegisterValues.containsKey(instructionIndex)) {
                Map<Integer, Long> regValues = instructionRegisterValues.get(instructionIndex);
                Set<Integer> changedRegs = instructionRegisterChanges.getOrDefault(instructionIndex, new HashSet<>());
                
                model.addRow(new Object[]{"", "", ""});
                model.addRow(new Object[]{"Register Changes", "", ""});
                for (int reg : changedRegs) {
                    if (reg >= 0 && reg < 32) {
                        Long value = regValues.get(reg + 2);
                        model.addRow(new Object[]{"R" + reg + " (changed)", 
                                                String.format("0x%08X", value), 
                                                "Register " + reg + " was modified"});
                    }
                }
            }
        }
        
        // Update logs - this would need to be implemented with the stored logs
        instructionLogsArea.setText("Raw logs for instruction " + (instructionIndex + 1) + ":\n\n");
        if (instructionIndex < parsedInstructions.size()) {
            InstructionInfo inst = parsedInstructions.get(instructionIndex);
            if (inst.logs != null) {
                for (String log : inst.logs) {
                    instructionLogsArea.append(log + "\n");
                }
            }
        } else {
            instructionLogsArea.append("No detailed logs available for this instruction.");
        }
        
        instructionDetailsFrame.setTitle("Instruction Details - #" + (instructionIndex + 1) + 
                                       " @ " + decodedTableModel.getValueAt(instructionIndex, 0));
    }
    
    // Store parsed instructions for details window
    private List<InstructionInfo> parsedInstructions = new ArrayList<>();
    
    // Enhanced CollapsiblePanel class with modern styling and features
    private static class CollapsiblePanel extends JPanel {
        private final JButton toggleButton;
        private final JPanel contentPanel;
        private boolean expanded;
        private String title;
        private Dimension expandedSize;
        
        public CollapsiblePanel(String title, JComponent content, boolean initiallyExpanded) {
            this.title = title;
            this.expanded = initiallyExpanded;
            
            setLayout(new BorderLayout());
            setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(220, 220, 220), 1),
                BorderFactory.createEmptyBorder(1, 1, 1, 1)
            ));
            
            // Create enhanced toggle button with modern styling
            toggleButton = new JButton();
            toggleButton.setFont(new Font(Font.SANS_SERIF, Font.BOLD, 11));
            toggleButton.setBackground(new Color(245, 245, 245));
            toggleButton.setBorder(BorderFactory.createEmptyBorder(10, 15, 10, 15));
            toggleButton.setHorizontalAlignment(SwingConstants.LEFT);
            toggleButton.setFocusPainted(false);
            toggleButton.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
            
            // Add hover effects
            toggleButton.addMouseListener(new java.awt.event.MouseAdapter() {
                @Override
                public void mouseEntered(java.awt.event.MouseEvent e) {
                    if (expanded) {
                        toggleButton.setBackground(new Color(235, 235, 235));
                    } else {
                        toggleButton.setBackground(new Color(250, 250, 250));
                    }
                }
                
                @Override
                public void mouseExited(java.awt.event.MouseEvent e) {
                    if (expanded) {
                        toggleButton.setBackground(new Color(245, 245, 245));
                    } else {
                        toggleButton.setBackground(new Color(240, 240, 240));
                    }
                }
            });
            
            toggleButton.addActionListener(_ -> toggleExpanded());
            
            // Content panel with subtle styling
            contentPanel = new JPanel(new BorderLayout());
            contentPanel.add(content, BorderLayout.CENTER);
            contentPanel.setBorder(BorderFactory.createEmptyBorder(5, 10, 10, 10));
            
            updateUIState();
        }
        
        private void toggleExpanded() {
            setExpanded(!expanded);
        }
        
        public void setExpanded(boolean expanded) {
            this.expanded = expanded;
            updateUIState();
        }
        
        public boolean isExpanded() {
            return expanded;
        }
        
        public void updateTitle(String newTitle) {
            this.title = newTitle;
            updateUIState();
        }
        
        private void updateUIState() {
            // Clear all components first
            removeAll();
            
            if (expanded) {
                toggleButton.setText("▼ " + title);
                toggleButton.setBackground(new Color(245, 245, 245));
                add(toggleButton, BorderLayout.NORTH);
                add(contentPanel, BorderLayout.CENTER);
                
                // Restore expanded size
                if (expandedSize != null) {
                    setPreferredSize(expandedSize);
                    setMinimumSize(new Dimension(0, 120)); // Reasonable minimum
                    setMaximumSize(new Dimension(Integer.MAX_VALUE, expandedSize.height));
                } else {
                    setPreferredSize(null);
                    setMinimumSize(new Dimension(0, 120));
                    setMaximumSize(new Dimension(Integer.MAX_VALUE, Integer.MAX_VALUE));
                }
                setVisible(true);
            } else {
                toggleButton.setText("▶ " + title);
                toggleButton.setPreferredSize(new Dimension(0, 35));
                toggleButton.setBackground(new Color(240, 240, 240));
                add(toggleButton, BorderLayout.NORTH);
                
                // Minimal collapsed size
                setPreferredSize(new Dimension(0, 35));
                setMinimumSize(new Dimension(0, 35));
                setMaximumSize(new Dimension(Integer.MAX_VALUE, 35));
                setVisible(true);
            }
            
            revalidate();
            repaint();
            
            // Trigger parent layout update recursively
            Container parent = getParent();
            while (parent != null) {
                if (parent instanceof JSplitPane) {
                    ((JSplitPane) parent).resetToPreferredSizes();
                }
                parent.revalidate();
                parent.repaint();
                parent = parent.getParent();
            }
        }
        
        @Override
        public void setPreferredSize(Dimension preferredSize) {
            super.setPreferredSize(preferredSize);
            if (expanded && preferredSize != null) {
                expandedSize = preferredSize;
            }
        }
    }
    
    // Helper class to track instruction information
    private static class InstructionInfo {
        String pc;
        int opcode, rd, rs1, rs2, imm;
        Set<Integer> changedRegisters = new HashSet<>();
        Map<Integer, Long> registerSnapshot;
        String flags;
        String instructionSet; // Raw instruction word (IS=...)
        List<String> logs = new ArrayList<>(); // All logs for this instruction

        InstructionInfo(String pc, int opcode, int rd, int rs1, int rs2, int imm) {
            this.pc = pc;
            this.opcode = opcode;
            this.rd = rd;
            this.rs1 = rs1;
            this.rs2 = rs2;
            this.imm = imm;
            this.instructionSet = null;
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
