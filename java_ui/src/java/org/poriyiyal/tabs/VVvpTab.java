package org.poriyiyal.tabs;

import javax.swing.*;
import java.awt.*;
import java.io.*;
import javax.swing.SwingWorker;

import org.poriyiyal.CpuIDE;
import org.poriyiyal.util.AppState;

/**
 * Combined V/VVP Tab for Verilog testbench files and compiled VVP files
 */
public class VVvpTab extends BaseTab {
    private JTabbedPane innerTabs;
    private JTextArea verilogArea;
    private JTextArea vvpArea;
    private JLabel verilogPathLabel;
    private JLabel vvpPathLabel;
    private JButton generateVvpButton;
    private JButton saveVerilogButton;
    private JButton runSimulationButton;
    
    public VVvpTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Initialize text areas
        verilogArea = new JTextArea();
        verilogArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        verilogArea.setEditable(true);
        verilogArea.setBackground(new Color(248, 248, 255));
        
        vvpArea = new JTextArea();
        vvpArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        vvpArea.setEditable(false);
        vvpArea.setBackground(new Color(255, 248, 248));
        
        // Initialize buttons
        generateVvpButton = new JButton("Generate VVP");
        generateVvpButton.addActionListener(e -> generateVvp());
        
        saveVerilogButton = new JButton("Save Verilog");
        saveVerilogButton.addActionListener(e -> saveVerilog());
        
        runSimulationButton = new JButton("Go To Simulation");
        runSimulationButton.addActionListener(e -> goToSimulationOnVvp());
        
        // Inner tabs
        innerTabs = new JTabbedPane();
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // Verilog file tab with dynamic location info and buttons
        JPanel verilogPanel = new JPanel(new BorderLayout());
        
        // Top panel with file info and buttons
        JPanel verilogTopPanel = new JPanel(new BorderLayout());
        verilogPathLabel = new JLabel("No Verilog testbench loaded");
        verilogPathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        verilogPathLabel.setForeground(Color.BLUE);
        verilogPathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        verilogPathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openVerilogFileLocation();
            }
        });
        
        JPanel verilogButtonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        verilogButtonPanel.add(generateVvpButton);
        verilogButtonPanel.add(saveVerilogButton);
        
        verilogTopPanel.add(verilogPathLabel, BorderLayout.WEST);
        verilogTopPanel.add(verilogButtonPanel, BorderLayout.EAST);
        
        verilogPanel.add(verilogTopPanel, BorderLayout.NORTH);
        verilogPanel.add(new JScrollPane(verilogArea), BorderLayout.CENTER);
        
        // VVP file tab with dynamic location info
        JPanel vvpPanel = new JPanel(new BorderLayout());
        vvpPathLabel = new JLabel("No VVP file loaded");
        vvpPathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        vvpPathLabel.setForeground(Color.BLUE);
        vvpPathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        vvpPathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openVvpFileLocation();
            }
        });
        // Add Run Simulation button to the VVP panel (top right)
        JPanel vvpButtonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        vvpButtonPanel.add(runSimulationButton);
        JPanel vvpTopPanel = new JPanel(new BorderLayout());
        vvpTopPanel.add(vvpPathLabel, BorderLayout.WEST);
        vvpTopPanel.add(vvpButtonPanel, BorderLayout.EAST);
        vvpPanel.add(vvpTopPanel, BorderLayout.NORTH);
        vvpPanel.add(new JScrollPane(vvpArea), BorderLayout.CENTER);
        
        innerTabs.addTab("Verilog Testbench", verilogPanel);
        innerTabs.addTab("VVP (Compiled)", vvpPanel);
        
        add(innerTabs, BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        // Determine if this is Verilog or VVP content based on content characteristics
        if (content.contains("module ") || content.contains("always") || content.contains("initial")) {
            loadVerilogContent(content);
        } else {
            loadVvpContent(content);
        }
    }
    
    public void loadVerilogContent(String content) {
        verilogArea.setText(content);
        innerTabs.setSelectedIndex(0); // Switch to Verilog tab
        updateStatus("Verilog testbench loaded");
    }
    
    public void loadVerilogContent(String content, String filePath) {
        verilogArea.setText(content);
        updateVerilogPath(filePath);
        innerTabs.setSelectedIndex(0); // Switch to Verilog tab
        updateStatus("Verilog testbench loaded from: " + (filePath != null ? new File(filePath).getName() : "unknown"));
    }
    
    public void loadVvpContent(String content) {
        vvpArea.setText(content);
        innerTabs.setSelectedIndex(1); // Switch to VVP tab
        updateStatus("VVP file loaded");
    }
    
    public void loadVerilogFromFile(File verilogFile) {
        try {
            String content = new String(java.nio.file.Files.readAllBytes(verilogFile.toPath()));
            verilogArea.setText(content);
            updateVerilogPath(verilogFile.getAbsolutePath());
            innerTabs.setSelectedIndex(0);
            updateStatus("Loaded Verilog: " + verilogFile.getName());
        } catch (Exception e) {
            verilogArea.setText("// Error loading Verilog file: " + e.getMessage());
            updateStatus("Error loading Verilog file");
        }
    }
    
    public void loadVvpFromFile(File vvpFile) {
        try {
            String content = new String(java.nio.file.Files.readAllBytes(vvpFile.toPath()));
            vvpArea.setText(content);
            updateVvpPath(vvpFile.getAbsolutePath());
            innerTabs.setSelectedIndex(1);
            updateStatus("Loaded VVP: " + vvpFile.getName());
        } catch (Exception e) {
            vvpArea.setText("// Error loading VVP file: " + e.getMessage());
            updateStatus("Error loading VVP file");
        }
    }
    
    private void generateVvp() {
        if (verilogArea.getText().trim().isEmpty()) {
            showError("Generate VVP", "No Verilog content to compile. Please load a Verilog testbench first.");
            return;
        }
        
        updateStatus("Generating VVP file...");
        
        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Determine base name from current file or generate default
                    String baseName = "testbench";
                    if (appState.getCurrentFile() != null) {
                        String fileName = appState.getCurrentFile().getName();
                        if (fileName.contains(".")) {
                            baseName = fileName.substring(0, fileName.lastIndexOf('.'));
                        }
                    }
                    
                    // Save current Verilog content to temporary file
                    File tempVerilogFile = new File("/Users/rajanpanneerselvam/work/hdl/temp/" + baseName + "_testbench.v");
                    tempVerilogFile.getParentFile().mkdirs();
                    
                    try (FileWriter writer = new FileWriter(tempVerilogFile)) {
                        writer.write(verilogArea.getText());
                    }
                    
                    // Generate VVP file path
                    File tempVvpFile = new File("/Users/rajanpanneerselvam/work/hdl/temp/" + baseName + "_testbench.vvp");
                    
                    // Build iverilog command
                    ProcessBuilder pb = new ProcessBuilder(
                        "iverilog", 
                        "-o", tempVvpFile.getAbsolutePath(),
                        tempVerilogFile.getAbsolutePath(),
                        "/Users/rajanpanneerselvam/work/hdl/processor/microprocessor_system.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/cpu/cpu_core.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/cpu/alu.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/cpu/register_file.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/memory/memory_controller.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/memory/mmu.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/io/uart.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/io/timer.v",
                        "/Users/rajanpanneerselvam/work/hdl/processor/io/interrupt_controller.v"
                    );
                    
                    pb.directory(new File("/Users/rajanpanneerselvam/work/hdl"));
                    
                    Process process = pb.start();
                    
                    // Read output
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("IVERILOG: " + line);
                        }
                    }
                    
                    // Read error output
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("IVERILOG ERROR: " + line);
                        }
                    }
                    
                    int exitCode = process.waitFor();
                    if (exitCode == 0) {
                        publish("✅ VVP generation successful!");
                        
                        // Update AppState with generated files
                        appState.addGeneratedFile("verilog", tempVerilogFile);
                        appState.addGeneratedFile("vvp", tempVvpFile);
                        
                        // Load the generated VVP file
                        SwingUtilities.invokeLater(() -> {
                            loadVvpFromFile(tempVvpFile);
                        });
                    } else {
                        publish("❌ VVP generation failed with exit code: " + exitCode);
                    }
                    
                } catch (Exception e) {
                    publish("VVP generation error: " + e.getMessage());
                }
                
                return null;
            }
            
            @Override
            protected void process(java.util.List<String> chunks) {
                // Show output in status area or log - for now just update status
                for (String chunk : chunks) {
                    System.out.println(chunk); // For debugging
                }
            }
            
            @Override
            protected void done() {
                updateStatus("VVP generation complete");
            }
        };
        
        worker.execute();
    }
    
    private void saveVerilog() {
        if (verilogArea.getText().trim().isEmpty()) {
            showError("Save Verilog", "No Verilog content to save.");
            return;
        }
        
        // Generate default filename based on current file
        String defaultName = "testbench.v";
        if (appState.getCurrentFile() != null) {
            String fileName = appState.getCurrentFile().getName();
            if (fileName.contains(".")) {
                String baseName = fileName.substring(0, fileName.lastIndexOf('.'));
                defaultName = baseName + "_testbench.v";
            }
        }
        
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setCurrentDirectory(new File("/Users/rajanpanneerselvam/work/hdl/temp"));
        fileChooser.setSelectedFile(new File(defaultName));
        
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = fileChooser.getSelectedFile();
            try (FileWriter writer = new FileWriter(file)) {
                writer.write(verilogArea.getText());
                updateVerilogPath(file.getAbsolutePath());
                updateStatus("Verilog saved: " + file.getName());
                showInfo("Save Verilog", "Verilog testbench saved successfully to:\n" + file.getAbsolutePath());
            } catch (Exception e) {
                showError("Save Verilog", "Error saving file: " + e.getMessage());
            }
        }
    }
    
    private void goToSimulationOnVvp() {
        // Find the VVP file path from AppState
        File vvpFile = appState.getGeneratedFile("vvp");
        if (vvpFile == null || !vvpFile.exists()) {
            showError("Run Simulation", "No VVP file found. Please generate VVP first.");
            return;
        }
        // Run vvp and show output in Simulation Log tab
        try {
            //ProcessBuilder pb = new ProcessBuilder("vvp", vvpFile.getAbsolutePath());
            //pb.directory(new File(System.getProperty("user.dir")));
            //Process process = pb.start();
            //BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            //StringBuilder output = new StringBuilder();
            //String line;
            //while ((line = reader.readLine()) != null) {
            //    output.append(line).append("\n");
            //}
            //int exitCode = process.waitFor();
            //output.append("\n[Process exited with code " + exitCode + "]\n");
            // Show in Simulation Log tab
            if (parentFrame instanceof CpuIDE) {
                CpuIDE ide = (CpuIDE) parentFrame;
                // Switch to Simulation tab instead of Sim Log
                ide.switchToTab("Simulation");
                // Optionally, update the simulation log area in SimulationTab if needed
                // ide.getSimulationTab().loadContent(output.toString());
            }
        } catch (Exception e) {
            showError("Run Simulation", "Failed to run VVP: " + e.getMessage());
        }
    }
    
    private void openVerilogFileLocation() {
        String path = verilogPathLabel.getText();
        if (path != null && path.startsWith("Path: ")) {
            openFileLocation(path.substring(6));
        }
    }
    
    private void openVvpFileLocation() {
        String path = vvpPathLabel.getText();
        if (path != null && path.startsWith("Path: ")) {
            openFileLocation(path.substring(6));
        }
    }
    
    private void openFileLocation(String filePath) {
        if (filePath == null || filePath.startsWith("No ") || filePath.isEmpty()) {
            return;
        }
        
        try {
            File file = new File(filePath);
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
                updateStatus("⚠️ File not found: " + filePath);
            }
        } catch (Exception e) {
            updateStatus("⚠️ Error opening file location: " + e.getMessage());
        }
    }
    
    public void updateVerilogPath(String filePath) {
        if (filePath != null && !filePath.isEmpty()) {
            verilogPathLabel.setText("Path: " + filePath);
        } else {
            verilogPathLabel.setText("No Verilog testbench loaded");
        }
    }
    
    public void updateVvpPath(String filePath) {
        if (filePath != null && !filePath.isEmpty()) {
            vvpPathLabel.setText("Path: " + filePath);
        } else {
            vvpPathLabel.setText("No VVP file loaded");
        }
    }
    
    @Override
    public void clearContent() {
        if (verilogArea != null) verilogArea.setText("");
        if (vvpArea != null) vvpArea.setText("");
        if (verilogPathLabel != null) verilogPathLabel.setText("No Verilog testbench loaded");
        if (vvpPathLabel != null) vvpPathLabel.setText("No VVP file loaded");
    }
    
    @Override
    public void saveContent() {
        // Save the currently visible tab content
        int selectedIndex = innerTabs.getSelectedIndex();
        if (selectedIndex == 0) {
            // Verilog tab is selected
            saveVerilog();
        }
        // VVP files are read-only, so no save needed for tab 1
    }
}
