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
    private JTabbedPane innerTabs;
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
    private Timer uartTimer;
    private Process simulationProcess;
    private boolean isSimulating = false;
    
    public SimulationTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Initialize text areas first
        verilogArea = new JTextArea();
        verilogArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        verilogArea.setEditable(false);
        verilogArea.setBackground(new Color(248, 248, 255));
        
        vvpArea = new JTextArea();
        vvpArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        vvpArea.setEditable(false);
        vvpArea.setBackground(new Color(255, 248, 248));
        
        // Inner tabs
        innerTabs = new JTabbedPane();
        
        // Verilog file tab with dynamic location info
        JPanel verilogPanel = new JPanel(new BorderLayout());
        verilogPathLabel = new JLabel("No Verilog file loaded");
        verilogPathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        verilogPathLabel.setForeground(Color.BLUE);
        verilogPathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        verilogPathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openFileLocation(verilogPathLabel.getText());
            }
        });
        verilogPanel.add(verilogPathLabel, BorderLayout.NORTH);
        verilogPanel.add(new JScrollPane(verilogArea), BorderLayout.CENTER);
        
        // VVP file tab with dynamic location info
        JPanel vvpPanel = new JPanel(new BorderLayout());
        vvpPathLabel = new JLabel("No VVP file loaded");
        vvpPathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        vvpPathLabel.setForeground(Color.BLUE);
        vvpPathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        vvpPathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openFileLocation(vvpPathLabel.getText());
            }
        });
        vvpPanel.add(vvpPathLabel, BorderLayout.NORTH);
        vvpPanel.add(new JScrollPane(vvpArea), BorderLayout.CENTER);
        
        // Simulation control tab
        JPanel simulatePanel = createSimulatePanel();
        
        innerTabs.addTab("Verilog Source", verilogPanel);
        innerTabs.addTab("VVP File", vvpPanel);
        innerTabs.addTab("Simulate", simulatePanel);
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
        
        JButton generateTestbenchButton = new JButton("Generate Testbench");
        generateTestbenchButton.addActionListener(e -> generateTestbench());
        
        dumpMemoryButton = new JButton("Dump Memory");
        dumpMemoryButton.addActionListener(e -> dumpMemory());
        
        cycleCountLabel = new JLabel("Cycles: 0");
        pcLabel = new JLabel("PC: 0x0000");
        
        controlPanel.add(generateTestbenchButton);
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
        setLayout(new BorderLayout());
        add(innerTabs, BorderLayout.CENTER);
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
        verilogArea.setText(content);
        innerTabs.setSelectedIndex(0); // Switch to Verilog tab
    }
    
    public void loadVvpContent(String content) {
        vvpArea.setText(content);
        innerTabs.setSelectedIndex(1); // Switch to VVP tab
    }
    
    public void startSimulation() {
        if (isSimulating) {
            showInfo("Simulation Running", "A simulation is already running. Stop it first.");
            return;
        }
        
        // Create necessary directories for VCD output
        createVcdDirectories();
        
        simulateButton.setEnabled(false);
        stopButton.setEnabled(true);
        isSimulating = true;
        appState.setSimulating(true);
        updateStatus("Starting simulation...");
        
        simulationLogArea.setText("Initializing simulation...\n");
        uartOutputArea.setText("");
        
        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Look for VVP file or compile Verilog
                    String vvpFile = findOrCreateVvpFile();
                    if (vvpFile == null) {
                        publish("ERROR: No VVP file found or Verilog compilation failed");
                        return null;
                    }
                    
                    publish("Starting VVP simulation: " + vvpFile);
                    
                    // Start VVP simulation
                    ProcessBuilder pb = new ProcessBuilder("vvp", vvpFile);
                    pb.directory(new File(vvpFile).getParentFile());
                    
                    simulationProcess = pb.start();
                    
                    // Read simulation output
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(simulationProcess.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null && isSimulating) {
                            publish("SIM: " + line);
                            
                            // Parse register updates if format is known
                            parseSimulationOutput(line);
                        }
                    }
                    
                    // Read error output
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(simulationProcess.getErrorStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null && isSimulating) {
                            publish("SIM ERROR: " + line);
                        }
                    }
                    
                    int exitCode = simulationProcess.waitFor();
                    publish("Simulation completed with exit code: " + exitCode);
                    
                } catch (Exception e) {
                    publish("Simulation error: " + e.getMessage());
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
        innerTabs.setSelectedIndex(2);
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
                // Ignore update errors
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
                        // Ignore file read errors
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
        if (!isSimulating) {
            showInfo("Memory Dump", "Start a simulation first before dumping memory.");
            return;
        }
        
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
                    long startAddr = Long.parseUnsignedLong(parts[0].trim().replace("0x", ""), 16);
                    long endAddr = Long.parseUnsignedLong(parts[1].trim().replace("0x", ""), 16);
                    
                    simulationLogArea.append("💾 Memory Dump (" + String.format("0x%08X", startAddr) + 
                                           " to " + String.format("0x%08X", endAddr) + "):\n");
                    
                    // Generate simulated memory dump (in real implementation, this would query the simulator)
                    for (long addr = startAddr; addr <= endAddr && addr < startAddr + 256; addr += 16) {
                        StringBuilder line = new StringBuilder();
                        line.append(String.format("0x%08X: ", addr));
                        
                        for (int i = 0; i < 16 && addr + i <= endAddr; i++) {
                            // Simulate some memory content (random for demo)
                            int value = (int)((addr + i) % 256);
                            line.append(String.format("%02X ", value));
                        }
                        
                        simulationLogArea.append(line.toString() + "\n");
                    }
                    
                    simulationLogArea.append("✅ Memory dump completed\n");
                    simulationLogArea.setCaretPosition(simulationLogArea.getDocument().getLength());
                } else {
                    simulationLogArea.append("❌ Invalid format. Use: 0x8000-0x8100\n");
                }
            } catch (NumberFormatException e) {
                simulationLogArea.append("❌ Invalid address format: " + e.getMessage() + "\n");
            }
        }
    }
    
    @Override
    public void clearContent() {
        if (verilogArea != null) verilogArea.setText("");
        if (vvpArea != null) vvpArea.setText("");
        if (simulationLogArea != null) simulationLogArea.setText("");
        if (uartOutputArea != null) uartOutputArea.setText("");
        
        // Reset register table
        if (registerTableModel != null) {
            for (int i = 0; i < 32; i++) {
                registerTableModel.setValueAt("0x00000000", i, 1);
                registerTableModel.setValueAt("0", i, 2);
                registerTableModel.setValueAt("IDLE", i, 3);
            }
        }
        
        if (cycleCountLabel != null) cycleCountLabel.setText("Cycles: 0");
        if (pcLabel != null) pcLabel.setText("PC: 0x0000");
    }
    
    /**
     * Try to load Verilog and VVP files from expected locations
     */
    public void loadSimulationFiles() {
        // Try to load Verilog file
        File verilogFile = new File("/Users/rajanpanneerselvam/work/hdl/processor/microprocessor_system_with_display.v");
        if (verilogFile.exists()) {
            try {
                String content = new String(java.nio.file.Files.readAllBytes(verilogFile.toPath()));
                verilogArea.setText(content);
                updateStatus("Loaded Verilog: " + verilogFile.getName());
            } catch (Exception e) {
                verilogArea.setText("// Error loading Verilog file: " + e.getMessage());
            }
        } else {
            verilogArea.setText("// Verilog file not found at: " + verilogFile.getAbsolutePath());
        }
        
        // Try to load VVP file
        File vvpFile = new File("/Users/rajanpanneerselvam/work/hdl/output/simulation.vvp");
        if (vvpFile.exists()) {
            try {
                String content = new String(java.nio.file.Files.readAllBytes(vvpFile.toPath()));
                vvpArea.setText(content);
                updateStatus("Loaded VVP: " + vvpFile.getName());
            } catch (Exception e) {
                vvpArea.setText("// Error loading VVP file: " + e.getMessage());
            }
        } else {
            vvpArea.setText("// VVP file not found at: " + vvpFile.getAbsolutePath());
        }
    }
    
    private void generateTestbench() {
        if (appState.getCurrentFile() == null) {
            showInfo("Generate Testbench", "Please open a source file first");
            return;
        }
        
        updateStatus("Generating testbench...");
        simulationLogArea.append("Generating testbench files...\n");
        
        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    File currentFile = appState.getCurrentFile();
                    String fileName = currentFile.getName();
                    String testName = fileName.substring(0, fileName.lastIndexOf('.'));
                    
                    // Determine file type for c_test_runner.py
                    String fileType = "c";
                    if (fileName.endsWith(".asm")) {
                        fileType = "assembly";
                    } else if (fileName.endsWith(".java")) {
                        fileType = "java";
                    }
                    
                    // Build command to run c_test_runner.py
                    ProcessBuilder pb = new ProcessBuilder(
                        "python3", 
                        "c_test_runner.py", 
                        ".", 
                        "--test", testName, 
                        "--type", fileType
                    );
                    
                    // Set working directory to hdl root
                    pb.directory(new File("/Users/rajanpanneerselvam/work/hdl"));
                    
                    publish("Running: python3 c_test_runner.py . --test " + testName + " --type " + fileType);
                    
                    Process process = pb.start();
                    
                    // Read stdout
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("TESTBENCH: " + line);
                        }
                    }
                    
                    // Read stderr
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("TESTBENCH ERROR: " + line);
                        }
                    }
                    
                    int exitCode = process.waitFor();
                    if (exitCode == 0) {
                        publish("✅ Testbench generation successful!");
                        
                        // Try to load generated Verilog and VVP files
                        SwingUtilities.invokeLater(() -> {
                            loadGeneratedSimulationFiles(testName);
                        });
                    } else {
                        publish("❌ Testbench generation failed with exit code: " + exitCode);
                    }
                    
                } catch (Exception e) {
                    publish("Testbench generation error: " + e.getMessage());
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
                updateStatus("Testbench generation complete");
            }
        };
        
        worker.execute();
    }
    
    private void loadGeneratedSimulationFiles(String testName) {
        // Try to load generated testbench file
        File testbenchFile = new File("/Users/rajanpanneerselvam/work/hdl/temp/tb_" + testName + ".v");
        if (testbenchFile.exists()) {
            try {
                String content = new String(java.nio.file.Files.readAllBytes(testbenchFile.toPath()));
                verilogArea.setText(content);
                updateVerilogPath(testbenchFile.getAbsolutePath());
                updateStatus("Loaded testbench: " + testbenchFile.getName());
                simulationLogArea.append("📁 Loaded testbench file: " + testbenchFile.getAbsolutePath() + "\n");
            } catch (Exception e) {
                simulationLogArea.append("Error loading testbench: " + e.getMessage() + "\n");
            }
        }
        
        // Try to load generated VVP file
        File vvpFile = new File("/Users/rajanpanneerselvam/work/hdl/temp/tb_" + testName + ".vvp");
        if (vvpFile.exists()) {
            try {
                String content = new String(java.nio.file.Files.readAllBytes(vvpFile.toPath()));
                vvpArea.setText(content);
                updateVvpPath(vvpFile.getAbsolutePath());
                updateStatus("Loaded VVP: " + vvpFile.getName());
                simulationLogArea.append("📁 Loaded VVP file: " + vvpFile.getAbsolutePath() + "\n");
                
                // Store VVP file for simulation
                appState.addGeneratedFile("vvp", vvpFile);
            } catch (Exception e) {
                simulationLogArea.append("Error loading VVP: " + e.getMessage() + "\n");
            }
        } else {
            simulationLogArea.append("ℹ️ VVP file not found at: " + vvpFile.getAbsolutePath() + "\n");
        }
        
        // Switch to VVP tab to show the generated files
        if (vvpFile.exists()) {
            innerTabs.setSelectedIndex(1); // VVP tab
        } else {
            innerTabs.setSelectedIndex(0); // Verilog tab
        }
    }
    
    private void createVcdDirectories() {
        try {
            // Create temp directory if it doesn't exist
            File tempDir = new File("/Users/rajanpanneerselvam/work/hdl/temp");
            if (!tempDir.exists()) {
                tempDir.mkdirs();
                simulationLogArea.append("📁 Created temp directory: " + tempDir.getAbsolutePath() + "\n");
            }
            
            // Create c_generated_vcd directory if it doesn't exist
            File vcdDir = new File("/Users/rajanpanneerselvam/work/hdl/temp/c_generated_vcd");
            if (!vcdDir.exists()) {
                vcdDir.mkdirs();
                simulationLogArea.append("📁 Created VCD directory: " + vcdDir.getAbsolutePath() + "\n");
            }
        } catch (Exception e) {
            simulationLogArea.append("⚠️ Error creating directories: " + e.getMessage() + "\n");
        }
    }
    
    private void openFileLocation(String filePath) {
        if (filePath == null || filePath.startsWith("No ") || filePath.isEmpty()) {
            return;
        }
        
        try {
            // Extract path from label text (remove "Path: " prefix if present)
            String path = filePath.startsWith("Path: ") ? filePath.substring(6) : filePath;
            File file = new File(path);
            
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
            } else {
                simulationLogArea.append("⚠️ File not found: " + path + "\n");
            }
        } catch (Exception e) {
            simulationLogArea.append("⚠️ Error opening file location: " + e.getMessage() + "\n");
        }
    }
    
    public void updateVerilogPath(String filePath) {
        if (filePath != null && !filePath.isEmpty()) {
            verilogPathLabel.setText("Path: " + filePath);
        } else {
            verilogPathLabel.setText("No Verilog file loaded");
        }
    }
    
    public void updateVvpPath(String filePath) {
        if (filePath != null && !filePath.isEmpty()) {
            vvpPathLabel.setText("Path: " + filePath);
        } else {
            vvpPathLabel.setText("No VVP file loaded");
        }
    }
}
