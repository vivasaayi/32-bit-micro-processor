package tabs;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import javax.swing.SwingWorker;
import java.util.Timer;
import java.util.TimerTask;
import util.AppState;

public class SimulationTab extends BaseTab {
    private JTextArea verilogArea;
    private JTextArea vvpArea;
    private JTextArea simulationLogArea;
    private JTextArea uartOutputArea;
    private JTable registerTable;
    private DefaultTableModel registerTableModel;
    private JButton simulateButton;
    private JButton stopButton;
    private JButton dumpMemoryButton;
    private JLabel cycleCountLabel;
    private JLabel pcLabel;
    private JLabel verilogPathLabel;
    private JLabel vvpPathLabel;
    private JLabel logFilePathLabel;
    private Timer uartTimer;
    private Process simulationProcess;
    private boolean isSimulating = false;
    
    public SimulationTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Remove innerTabs and nested tabs. Use a single main panel.
        setLayout(new BorderLayout());

        // Top panel with controls and file info
        JPanel controlPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));

        // V and VVP file labels
        verilogPathLabel = new JLabel("V file: (not loaded)");
        verilogPathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        verilogPathLabel.setForeground(Color.BLUE);
        verilogPathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        verilogPathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                SimulationTab.this.openFileLocation(verilogPathLabel.getText().replace("V file: ", ""));
            }
        });
        vvpPathLabel = new JLabel("VVP file: (not loaded)");
        vvpPathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        vvpPathLabel.setForeground(Color.BLUE);
        vvpPathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        vvpPathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                SimulationTab.this.openFileLocation(vvpPathLabel.getText().replace("VVP file: ", ""));
            }
        });

        // Start/Stop Simulation and Dump Memory
        simulateButton = new JButton("Start Simulation");
        simulateButton.addActionListener(e -> startSimulation());
        stopButton = new JButton("Stop Simulation");
        stopButton.addActionListener(e -> stopSimulation());
        stopButton.setEnabled(false);
        dumpMemoryButton = new JButton("Dump Memory");
        dumpMemoryButton.addActionListener(e -> dumpMemory());
        cycleCountLabel = new JLabel("Cycles: 0");
        pcLabel = new JLabel("PC: 0x0000");

        controlPanel.add(verilogPathLabel);
        controlPanel.add(Box.createHorizontalStrut(10));
        controlPanel.add(vvpPathLabel);
        controlPanel.add(Box.createHorizontalStrut(10));
        controlPanel.add(simulateButton);
        controlPanel.add(stopButton);
        controlPanel.add(dumpMemoryButton);
        controlPanel.add(Box.createHorizontalStrut(20));
        controlPanel.add(cycleCountLabel);
        controlPanel.add(Box.createHorizontalStrut(10));
        controlPanel.add(pcLabel);

        // Center panel with split panes
        JSplitPane mainSplit = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        JSplitPane leftSplit = new JSplitPane(JSplitPane.VERTICAL_SPLIT);

        simulationLogArea = new JTextArea();
        simulationLogArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        simulationLogArea.setEditable(false);
        simulationLogArea.setBackground(Color.BLACK);
        simulationLogArea.setForeground(Color.GREEN);
        uartOutputArea = new JTextArea(8, 0);
        uartOutputArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        uartOutputArea.setEditable(false);
        uartOutputArea.setBackground(new Color(0, 0, 50));
        uartOutputArea.setForeground(Color.CYAN);

        // Add log file path label above the simulation log area
        logFilePathLabel = new JLabel("Log file: (not saved)");
        logFilePathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        logFilePathLabel.setForeground(Color.BLUE);
        logFilePathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        logFilePathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                SimulationTab.this.openFileLocation(logFilePathLabel.getText().replace("Log file: ", ""));
            }
        });

        JPanel logPanel = new JPanel(new BorderLayout());
        JPanel logLabelPanel = new JPanel(new BorderLayout());
        logLabelPanel.add(new JLabel("Simulation Log:"), BorderLayout.WEST);
        logLabelPanel.add(logFilePathLabel, BorderLayout.EAST);
        logPanel.add(logLabelPanel, BorderLayout.NORTH);
        logPanel.add(new JScrollPane(simulationLogArea), BorderLayout.CENTER);
        JPanel uartPanel = new JPanel(new BorderLayout());
        uartPanel.add(new JLabel("UART Output:"), BorderLayout.NORTH);
        uartPanel.add(new JScrollPane(uartOutputArea), BorderLayout.CENTER);
        leftSplit.setTopComponent(logPanel);
        leftSplit.setBottomComponent(uartPanel);
        leftSplit.setDividerLocation(300);

        createRegisterTable();
        JPanel registerPanel = new JPanel(new BorderLayout());
        registerPanel.add(new JLabel("CPU Registers:"), BorderLayout.NORTH);
        registerPanel.add(new JScrollPane(registerTable), BorderLayout.CENTER);
        mainSplit.setLeftComponent(leftSplit);
        mainSplit.setRightComponent(registerPanel);
        mainSplit.setDividerLocation(600);

        add(controlPanel, BorderLayout.NORTH);
        add(mainSplit, BorderLayout.CENTER);
    }
    
    private JPanel createSimulatePanel() {
        JPanel panel = new JPanel(new BorderLayout());
        
        // Top panel with controls
        JPanel controlPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        
        simulateButton = new JButton("Start Simulation");
        simulateButton.addActionListener(e -> startSimulation());
        
        stopButton = new JButton("Stop Simulation");
        stopButton.addActionListener(e -> stopSimulation());
        stopButton.setEnabled(false);
        
        dumpMemoryButton = new JButton("Dump Memory");
        dumpMemoryButton.addActionListener(e -> dumpMemory());
        
        cycleCountLabel = new JLabel("Cycles: 0");
        pcLabel = new JLabel("PC: 0x0000");
        
        controlPanel.add(simulateButton);
        controlPanel.add(stopButton);
        controlPanel.add(dumpMemoryButton);
        controlPanel.add(Box.createHorizontalStrut(20));
        controlPanel.add(cycleCountLabel);
        controlPanel.add(Box.createHorizontalStrut(10));
        controlPanel.add(pcLabel);
        
        // Center panel with split panes
        JSplitPane mainSplit = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        
        // Left side: simulation log and UART output
        JSplitPane leftSplit = new JSplitPane(JSplitPane.VERTICAL_SPLIT);
        
        simulationLogArea = new JTextArea();
        simulationLogArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        simulationLogArea.setEditable(false);
        simulationLogArea.setBackground(Color.BLACK);
        simulationLogArea.setForeground(Color.GREEN);
        
        uartOutputArea = new JTextArea(8, 0);
        uartOutputArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        uartOutputArea.setEditable(false);
        uartOutputArea.setBackground(new Color(0, 0, 50));
        uartOutputArea.setForeground(Color.CYAN);
        
        JPanel logPanel = new JPanel(new BorderLayout());
        logPanel.add(new JLabel("Simulation Log:"), BorderLayout.NORTH);
        logPanel.add(new JScrollPane(simulationLogArea), BorderLayout.CENTER);
        
        JPanel uartPanel = new JPanel(new BorderLayout());
        uartPanel.add(new JLabel("UART Output:"), BorderLayout.NORTH);
        uartPanel.add(new JScrollPane(uartOutputArea), BorderLayout.CENTER);
        
        leftSplit.setTopComponent(logPanel);
        leftSplit.setBottomComponent(uartPanel);
        leftSplit.setDividerLocation(300);
        
        // Right side: register table
        createRegisterTable();
        JPanel registerPanel = new JPanel(new BorderLayout());
        registerPanel.add(new JLabel("CPU Registers:"), BorderLayout.NORTH);
        registerPanel.add(new JScrollPane(registerTable), BorderLayout.CENTER);
        
        mainSplit.setLeftComponent(leftSplit);
        mainSplit.setRightComponent(registerPanel);
        mainSplit.setDividerLocation(600);
        
        panel.add(controlPanel, BorderLayout.NORTH);
        panel.add(mainSplit, BorderLayout.CENTER);
        
        return panel;
    }
    
    private void createRegisterTable() {
        String[] columnNames = {"Register", "Value (Hex)", "Value (Dec)", "Status"};
        registerTableModel = new DefaultTableModel(columnNames, 0) {
            @Override
            public boolean isCellEditable(int row, int column) {
                return false;
            }
        };
        
        // Initialize with R0-R31
        for (int i = 0; i <= 31; i++) {
            registerTableModel.addRow(new Object[]{"R" + i, "0x00000000", "0", "OK"});
        }
        
        registerTable = new JTable(registerTableModel);
        registerTable.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        registerTable.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    }
    
    @Override
    protected void setupLayout() {
        // No-op: layout is handled in initializeComponents
    }
    
    @Override
    public void loadContent(String content) {
        // Default to loading in simulation log
        simulationLogArea.setText(content);
    }
    
    @Override
    public void saveContent() {
        // Simulation content is typically read-only
    }
    
    public void loadVerilogContent(String content) {
        // Optionally update V file label
        verilogArea.setText(content);
    }
    public void loadVvpContent(String content) {
        // Optionally update VVP file label
        vvpArea.setText(content);
    }
    public void startSimulation() {
        if (isSimulating) {
            showInfo("Simulation Running", "A simulation is already running. Stop it first.");
            return;
        }
        simulateButton.setEnabled(false);
        stopButton.setEnabled(true);
        isSimulating = true;
        appState.setSimulating(true);
        updateStatus("Starting simulation...");
        simulationLogArea.setText("Initializing simulation...\n");
        uartOutputArea.setText("");
        // Capture current test name before SwingWorker
        final String currentTestName = getCurrentTestName();

        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            private StringBuilder logBuffer = new StringBuilder();
            
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Look for VVP file or compile Verilog
                    String vvpFile = findOrCreateVvpFile();
                    if (vvpFile == null) {
                        String errorMsg = "ERROR: No VVP file found or Verilog compilation failed";
                        publish(errorMsg);
                        logBuffer.append(errorMsg).append("\n");
                        return null;
                    }
                    
                    String startMsg = "Starting VVP simulation: " + vvpFile;
                    publish(startMsg);
                    logBuffer.append(startMsg).append("\n");
                    
                    // Start VVP simulation
                    ProcessBuilder pb = new ProcessBuilder("vvp", vvpFile);
                    pb.directory(new File(vvpFile).getParentFile());
                    
                    simulationProcess = pb.start();
                    
                    // Read simulation output
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(simulationProcess.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null && isSimulating) {
                            String simLine = "SIM: " + line;
                            publish(simLine);
                            logBuffer.append(simLine).append("\n");
                            
                            // Parse register updates if format is known
                            parseSimulationOutput(line);
                        }
                    }
                    
                    // Read error output
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(simulationProcess.getErrorStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null && isSimulating) {
                            String errLine = "SIM ERROR: " + line;
                            publish(errLine);
                            logBuffer.append(errLine).append("\n");
                        }
                    }
                    
                    int exitCode = simulationProcess.waitFor();
                    String exitMsg = "Simulation completed with exit code: " + exitCode;
                    publish(exitMsg);
                    logBuffer.append(exitMsg).append("\n");
                    
                    // After simulation, update Sim Log and VCD tabs, and save log to file
                    String logFilePath = "/Users/rajanpanneerselvam/work/hdl/temp/" + currentTestName + ".log";
                    try (FileWriter logWriter = new FileWriter(logFilePath)) {
                        System.out.println("Simulation log saved to: " + logFilePath);
                        System.out.println("Simulation log content length: " + logBuffer.length() + " characters");
                        System.out.println("First 500 chars of log:\n" + logBuffer.substring(0, Math.min(500, logBuffer.length())));
                        logWriter.write(logBuffer.toString());
                        SwingUtilities.invokeLater(() -> logFilePathLabel.setText("Log file: " + logFilePath));
                    } catch (Exception e) {
                        e.printStackTrace(); // Log file write errors
                    }
                    if (parentFrame instanceof main.CpuIDE) {
                        main.CpuIDE ide = (main.CpuIDE) parentFrame;
                        // Update simulation log in Sim Log tab without switching tabs
                        SwingUtilities.invokeLater(() -> {
                            ide.updateSimulationLogTab(logBuffer.toString());
                        });
                        // Try to load VCD file in VCD tab
                        String vcdPath = "/Users/rajanpanneerselvam/work/hdl/temp/" + currentTestName + ".vcd";
                        File vcdFile = new File(vcdPath);
                        if (vcdFile.exists()) {
                            try {
                                String vcdContent = new String(java.nio.file.Files.readAllBytes(vcdFile.toPath()));
                                ide.getVcdTab().loadContent(vcdContent);
                            } catch (Exception e) {
                                e.printStackTrace(); // Log VCD load errors
                            }
                        }
                    }
                } catch (Exception e) {
                    String errorMsg = "Simulation error: " + e.getMessage();
                    publish(errorMsg);
                    logBuffer.append(errorMsg).append("\n");
                    e.printStackTrace(); // Log simulation errors
                }
                
                return null;
            }
            
            @Override
            protected void process(java.util.List<String> chunks) {
                for (String chunk : chunks) {
                    simulationLogArea.append(chunk + "\n");
                    simulationLogArea.setCaretPosition(simulationLogArea.getDocument().getLength());
                }
            }
            
            @Override
            protected void done() {
                stopSimulation();
            }
        };
        
        worker.execute();
        
        // Start UART monitoring
        startUartMonitoring();
        
        // Switch to simulation tab
        // innerTabs.setSelectedIndex(2);
    }
    
    // Returns the base name (without extension) of the current .v file for simulation artifact naming
    private String getCurrentTestName() {
        File currentFile = appState.getCurrentFile();
        if (currentFile != null) {
            String fileName = currentFile.getName();
            int dot = fileName.lastIndexOf('.');
            if (dot > 0) return fileName.substring(0, dot);
            return fileName;
        }
        return "testbench";
    }
    
    private String findOrCreateVvpFile() {
        // First priority: Check for generated VVP file from testbench generation
        File vvpFile = appState.getGeneratedFile("vvp");
        if (vvpFile != null && vvpFile.exists()) {
            return vvpFile.getAbsolutePath();
        }
        
        // Second priority: Look for testbench VVP files based on current file
        File currentFile = appState.getCurrentFile();
        if (currentFile != null) {
            String baseName = currentFile.getName();
            if (baseName.contains(".")) {
                baseName = baseName.substring(0, baseName.lastIndexOf('.'));
            }
            
            // Check for testbench VVP file in temp directory
            File testbenchVvp = new File("/Users/rajanpanneerselvam/work/hdl/temp/tb_" + baseName + ".vvp");
            if (testbenchVvp.exists()) {
                return testbenchVvp.getAbsolutePath();
            }
        }
        
        // Third priority: Try to compile current Verilog file
        if (currentFile != null) {
            String verilogFile = currentFile.getAbsolutePath();
            if (verilogFile.endsWith(".v")) {
                String vvpOutput = verilogFile.replace(".v", ".vvp");
                try {
                    // Compile Verilog to VVP
                    ProcessBuilder pb = new ProcessBuilder("iverilog", "-o", vvpOutput, verilogFile);
                    Process process = pb.start();
                    int exitCode = process.waitFor();
                    
                    if (exitCode == 0) {
                        return vvpOutput;
                    }
                } catch (Exception e) {
                    // Compilation failed
                }
            }
        }
        
        return null;
    }
    
    private void parseSimulationOutput(String line) {
        // Parse simulation output for register updates
        // Example format: "DEBUG CPU: R1 = 0x12345678"
        if (line.contains("R") && line.contains("=")) {
            try {
                // Extract register number and value
                String[] parts = line.split("=");
                if (parts.length == 2) {
                    String regPart = parts[0].trim();
                    String valuePart = parts[1].trim();
                    
                    if (regPart.contains("R")) {
                        int regStart = regPart.indexOf("R") + 1;
                        int regEnd = regStart;
                        while (regEnd < regPart.length() && Character.isDigit(regPart.charAt(regEnd))) {
                            regEnd++;
                        }
                        
                        if (regEnd > regStart) {
                            int regNum = Integer.parseInt(regPart.substring(regStart, regEnd));
                            if (regNum >= 0 && regNum <= 31) {
                                updateRegisterValue(regNum, valuePart);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                // Ignore parsing errors
            }
        }
        
        // Parse cycle count and PC
        if (line.contains("PC=")) {
            try {
                int pcIndex = line.indexOf("PC=") + 3;
                String pcValue = line.substring(pcIndex).split("\\s+")[0];
                SwingUtilities.invokeLater(() -> pcLabel.setText("PC: " + pcValue));
            } catch (Exception e) {
                // Ignore parsing errors
            }
        }
    }
    
    private void updateRegisterValue(int regNum, String value) {
        SwingUtilities.invokeLater(() -> {
            try {
                // Clean up value string
                String cleanValue = value.trim().replace("0x", "");
                if (cleanValue.length() > 8) {
                    cleanValue = cleanValue.substring(0, 8);
                }
                
                long longValue = Long.parseLong(cleanValue, 16);
                int intValue = (int) longValue;
                
                registerTableModel.setValueAt("0x" + String.format("%08X", intValue), regNum, 1);
                registerTableModel.setValueAt(String.valueOf(intValue), regNum, 2);
                registerTableModel.setValueAt("UPDATED", regNum, 3);
                
            } catch (Exception e) {
                e.printStackTrace(); // Log update errors
            }
        });
    }
    
    private void startUartMonitoring() {
        uartTimer = new Timer();
        uartTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                if (!isSimulating) {
                    uartTimer.cancel();
                    return;
                }
                
                // Check for UART output file
                File uartFile = new File("/tmp/uart_output.txt");
                if (uartFile.exists()) {
                    try {
                        String content = new String(java.nio.file.Files.readAllBytes(uartFile.toPath()));
                        SwingUtilities.invokeLater(() -> {
                            if (!content.equals(uartOutputArea.getText())) {
                                uartOutputArea.setText(content);
                                uartOutputArea.setCaretPosition(uartOutputArea.getDocument().getLength());
                            }
                        });
                    } catch (Exception e) {
                        e.printStackTrace(); // Log UART file read errors
                    }
                }
            }
        }, 1000, 500); // Check every 500ms after 1s delay
    }
    
    public void stopSimulation() {
        isSimulating = false;
        appState.setSimulating(false);
        
        if (simulationProcess != null) {
            simulationProcess.destroy();
            simulationProcess = null;
        }
        
        if (uartTimer != null) {
            uartTimer.cancel();
            uartTimer = null;
        }
        
        simulateButton.setEnabled(true);
        stopButton.setEnabled(false);
        updateStatus("Simulation stopped");
    }
    
    private void dumpMemory() {
        // Allow memory dump at any time (remove simulation check)
        String input = JOptionPane.showInputDialog(this, 
            "Enter memory range (format: start_addr-end_addr, e.g., 0x8000-0x8100):",
            "Memory Dump",
            JOptionPane.QUESTION_MESSAGE);
        
        if (input != null && !input.trim().isEmpty()) {
            updateStatus("Dumping memory range: " + input);
            simulationLogArea.append("📋 Memory dump requested: " + input + "\n");
            
            // Parse the range and create a simulated memory dump
            try {
                String[] parts = input.trim().split("-");
                if (parts.length == 2) {
                    long startAddr = Long.parseLong(parts[0], 16);
                    long endAddr = Long.parseLong(parts[1], 16);
                    
                    // Limit range to 32 bits
                    if (startAddr < 0 || endAddr < 0 || startAddr > 0xFFFFFFFFL || endAddr > 0xFFFFFFFFL || startAddr > endAddr) {
                        throw new IllegalArgumentException("Invalid address range");
                    }
                    
                    // Simulate memory dump (replace with actual memory access in real implementation)
                    StringBuilder dumpBuilder = new StringBuilder();
                    dumpBuilder.append("Memory Dump from ")
                        .append(String.format("0x%08X", startAddr)).append(" to ")
                        .append(String.format("0x%08X", endAddr)).append(":\n");
                    
                    for (long addr = startAddr; addr <= endAddr; addr += 4) {
                        // Simulate reading 4 bytes from memory
                        long value = (addr & 0xFFFFFFFFL) | ((addr + 1) & 0xFFFFFFFFL) << 8 | ((addr + 2) & 0xFFFFFFFFL) << 16 | ((addr + 3) & 0xFFFFFFFFL) << 24;
                        dumpBuilder.append(String.format("0x%08X: 0x%08X\n", addr, value));
                    }
                    
                    // Update simulation log with memory dump
                    simulationLogArea.append(dumpBuilder.toString());
                } else {
                    throw new IllegalArgumentException("Invalid input format");
                }
            } catch (Exception e) {
                showError("Memory Dump Error", "Failed to dump memory: " + e.getMessage());
                e.printStackTrace(); // Log memory dump errors
            }
        }
    }
    
    // Opens the file location in the system file explorer
    private void openFileLocation(String filePath) {
        if (filePath == null || filePath.trim().isEmpty() || filePath.contains("not loaded") || filePath.contains("not saved")) return;
        try {
            File file = new File(filePath);
            if (file.exists()) {
                String os = System.getProperty("os.name").toLowerCase();
                if (os.contains("mac")) {
                    Runtime.getRuntime().exec(new String[]{"open", "-R", file.getAbsolutePath()});
                } else if (os.contains("windows")) {
                    Runtime.getRuntime().exec(new String[]{"explorer", "/select,", file.getAbsolutePath()});
                } else {
                    Runtime.getRuntime().exec(new String[]{"xdg-open", file.getParent()});
                }
            }
        } catch (Exception e) {
            e.printStackTrace(); // Log file open errors
        }
    }
}
