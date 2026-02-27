package org.poriyiyal.dialogs;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.File;
import java.util.HashMap;
import java.util.Map;

import org.poriyiyal.util.EnvLoader;

/**
 * Settings dialog for configuring environment variables
 */
public class SettingsDialog extends JDialog {
    private final Map<String, JTextField> pathFields = new HashMap<>();
    private final Map<String, JButton> browseButtons = new HashMap<>();
    private JButton saveButton;
    private JButton cancelButton;
    private JButton resetButton;
    private JLabel statusLabel;
    private boolean settingsChanged = false;
    
    // Environment variable definitions with descriptions
    private final String[][] envVarDefinitions = {
        {"HDL_BASE_DIR", "HDL Base Directory", "Base directory for HDL files (where iverilog commands are executed)"},
        {"TEMP_DIR", "Temporary Directory", "Directory for generated .v and .vvp files"},
        {"PROCESSOR_BASE_DIR", "Processor Directory", "Base directory for processor modules"},
        {"MICROPROCESSOR_SYSTEM_V", "Microprocessor System", "Path to microprocessor_system.v file"},
        {"CPU_CORE_V", "CPU Core", "Path to cpu_core.v file"},
        {"ALU_V", "ALU Module", "Path to alu.v file"},
        {"REGISTER_FILE_V", "Register File", "Path to register_file.v file"},
        {"MEMORY_CONTROLLER_V", "Memory Controller", "Path to memory_controller.v file"},
        {"MMU_V", "MMU Module", "Path to mmu.v file"},
        {"UART_V", "UART Module", "Path to uart.v file"},
        {"TIMER_V", "Timer Module", "Path to timer.v file"},
        {"INTERRUPT_CONTROLLER_V", "Interrupt Controller", "Path to interrupt_controller.v file"}
    };
    
    public SettingsDialog(JFrame parent) {
        super(parent, "AruviIDE Settings", true);
        initializeComponents();
        setupLayout();
        loadCurrentSettings();
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setSize(800, 700);
        setLocationRelativeTo(parent);
    }
    
    private void initializeComponents() {
        // Create components for each environment variable
        for (String[] envVar : envVarDefinitions) {
            String key = envVar[0];
            
            JTextField textField = new JTextField(40);
            textField.setToolTipText(envVar[2]);
            pathFields.put(key, textField);
            
            JButton browseButton = new JButton("Browse...");
            browseButton.addActionListener(e -> browseForPath(key, envVar[1]));
            browseButtons.put(key, browseButton);
        }
        
        // Dialog buttons
        saveButton = new JButton("Save Settings");
        saveButton.addActionListener(e -> saveSettings());
        saveButton.setPreferredSize(new Dimension(120, 30));
        
        cancelButton = new JButton("Cancel");
        cancelButton.addActionListener(e -> dispose());
        cancelButton.setPreferredSize(new Dimension(80, 30));
        
        resetButton = new JButton("Reset to Auto-Detected");
        resetButton.addActionListener(e -> resetToAutoDetected());
        resetButton.setPreferredSize(new Dimension(160, 30));
        
        // Status label
        statusLabel = new JLabel("Configure your environment paths below");
        statusLabel.setFont(statusLabel.getFont().deriveFont(Font.ITALIC, 11f));
        statusLabel.setForeground(Color.GRAY);
    }
    
    private void setupLayout() {
        setLayout(new BorderLayout());
        
        // Main panel with scroll pane
        JPanel mainPanel = new JPanel();
        mainPanel.setLayout(new BoxLayout(mainPanel, BoxLayout.Y_AXIS));
        mainPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        
        // Add title and description
        JLabel titleLabel = new JLabel("Environment Configuration");
        titleLabel.setFont(titleLabel.getFont().deriveFont(Font.BOLD, 16f));
        titleLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        mainPanel.add(titleLabel);
        
        mainPanel.add(Box.createVerticalStrut(5));
        
        JTextArea descriptionArea = new JTextArea(
            "Configure paths for HDL tools and modules. Leave fields empty to use auto-detected values.\n" +
            "Changes will be saved to the .env file in your project directory."
        );
        descriptionArea.setEditable(false);
        descriptionArea.setOpaque(false);
        descriptionArea.setFont(descriptionArea.getFont().deriveFont(Font.ITALIC));
        descriptionArea.setAlignmentX(Component.LEFT_ALIGNMENT);
        mainPanel.add(descriptionArea);
        
        mainPanel.add(Box.createVerticalStrut(15));
        
        // Group settings by category
        addSettingsGroup(mainPanel, "Base Directories", new String[][]{
            {"HDL_BASE_DIR", "HDL Base Directory", "Base directory for HDL files"},
            {"TEMP_DIR", "Temporary Directory", "Directory for generated files"},
            {"PROCESSOR_BASE_DIR", "Processor Directory", "Base directory for processor modules"}
        });
        
        addSettingsGroup(mainPanel, "Core Processor Modules", new String[][]{
            {"MICROPROCESSOR_SYSTEM_V", "Microprocessor System", "microprocessor_system.v"},
            {"CPU_CORE_V", "CPU Core", "cpu_core.v"},
            {"ALU_V", "ALU Module", "alu.v"},
            {"REGISTER_FILE_V", "Register File", "register_file.v"}
        });
        
        addSettingsGroup(mainPanel, "Memory Modules", new String[][]{
            {"MEMORY_CONTROLLER_V", "Memory Controller", "memory_controller.v"},
            {"MMU_V", "MMU Module", "mmu.v"}
        });
        
        addSettingsGroup(mainPanel, "IO Modules", new String[][]{
            {"UART_V", "UART Module", "uart.v"},
            {"TIMER_V", "Timer Module", "timer.v"},
            {"INTERRUPT_CONTROLLER_V", "Interrupt Controller", "interrupt_controller.v"}
        });
        
        // Wrap in scroll pane
        JScrollPane scrollPane = new JScrollPane(mainPanel);
        scrollPane.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_AS_NEEDED);
        scrollPane.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
        add(scrollPane, BorderLayout.CENTER);
        
        // Button panel
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.add(resetButton);
        buttonPanel.add(Box.createHorizontalStrut(10));
        buttonPanel.add(cancelButton);
        buttonPanel.add(saveButton);
        
        // Bottom panel with status and buttons
        JPanel bottomPanel = new JPanel(new BorderLayout());
        bottomPanel.setBorder(BorderFactory.createEmptyBorder(5, 10, 10, 10));
        bottomPanel.add(statusLabel, BorderLayout.WEST);
        bottomPanel.add(buttonPanel, BorderLayout.EAST);
        add(bottomPanel, BorderLayout.SOUTH);
    }
    
    private void addSettingsGroup(JPanel parent, String groupTitle, String[][] groupVars) {
        JPanel groupPanel = new JPanel();
        groupPanel.setLayout(new BoxLayout(groupPanel, BoxLayout.Y_AXIS));
        groupPanel.setBorder(BorderFactory.createTitledBorder(
            BorderFactory.createEtchedBorder(), 
            groupTitle, 
            TitledBorder.LEFT, 
            TitledBorder.TOP
        ));
        groupPanel.setAlignmentX(Component.LEFT_ALIGNMENT);
        
        for (String[] envVar : groupVars) {
            String key = envVar[0];
            String label = envVar[1];
            
            JPanel rowPanel = new JPanel(new BorderLayout(5, 5));
            rowPanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, 30));
            
            JLabel nameLabel = new JLabel(label + ":");
            nameLabel.setPreferredSize(new Dimension(180, 25));
            rowPanel.add(nameLabel, BorderLayout.WEST);
            
            JTextField textField = pathFields.get(key);
            rowPanel.add(textField, BorderLayout.CENTER);
            
            JButton browseButton = browseButtons.get(key);
            browseButton.setPreferredSize(new Dimension(80, 25));
            rowPanel.add(browseButton, BorderLayout.EAST);
            
            groupPanel.add(rowPanel);
            groupPanel.add(Box.createVerticalStrut(5));
        }
        
        parent.add(groupPanel);
        parent.add(Box.createVerticalStrut(10));
    }
    
    private void loadCurrentSettings() {
        for (String[] envVar : envVarDefinitions) {
            String key = envVar[0];
            String value = EnvLoader.getEnv(key);
            if (value != null) {
                pathFields.get(key).setText(value);
            }
        }
    }
    
    private void browseForPath(String envKey, String title) {
        JTextField textField = pathFields.get(envKey);
        String currentPath = textField.getText().trim();
        
        JFileChooser fileChooser = new JFileChooser();
        fileChooser.setDialogTitle("Select " + title);
        
        // Set initial directory
        if (!currentPath.isEmpty()) {
            File currentFile = new File(currentPath);
            if (currentFile.exists()) {
                if (currentFile.isDirectory()) {
                    fileChooser.setCurrentDirectory(currentFile);
                } else {
                    fileChooser.setCurrentDirectory(currentFile.getParentFile());
                    fileChooser.setSelectedFile(currentFile);
                }
            }
        }
        
        // Determine if we're selecting a file or directory
        if (envKey.endsWith("_DIR")) {
            fileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        } else if (envKey.endsWith("_V")) {
            fileChooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
            fileChooser.setFileFilter(new javax.swing.filechooser.FileNameExtensionFilter(
                "Verilog Files (*.v)", "v"));
        } else {
            fileChooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        }
        
        int result = fileChooser.showOpenDialog(this);
        if (result == JFileChooser.APPROVE_OPTION) {
            File selectedFile = fileChooser.getSelectedFile();
            textField.setText(selectedFile.getAbsolutePath());
            settingsChanged = true;
            updateStatus("Path updated for " + title);
        }
    }
    
    private void updateStatus(String message) {
        statusLabel.setText(message);
        // Clear status after 3 seconds
        Timer timer = new Timer(3000, e -> statusLabel.setText("Configure your environment paths below"));
        timer.setRepeats(false);
        timer.start();
    }
    
    private void saveSettings() {
        try {
            // Create .env file content
            StringBuilder envContent = new StringBuilder();
            envContent.append("# AruviIDE Environment Configuration\n");
            envContent.append("# Generated by AruviIDE Settings Dialog\n");
            envContent.append("# ").append(java.time.LocalDateTime.now()).append("\n\n");
            
            boolean hasValues = false;
            for (String[] envVar : envVarDefinitions) {
                String key = envVar[0];
                String description = envVar[2];
                String value = pathFields.get(key).getText().trim();
                
                envContent.append("# ").append(description).append("\n");
                if (!value.isEmpty()) {
                    envContent.append(key).append("=").append(value).append("\n");
                    hasValues = true;
                } else {
                    envContent.append("# ").append(key).append("=\n");
                }
                envContent.append("\n");
            }
            
            // Save to .env file
            File envFile = new File(".env");
            try (java.io.FileWriter writer = new java.io.FileWriter(envFile)) {
                writer.write(envContent.toString());
            }
            
            // Force reload of environment
            EnvLoader.reloadEnvironment();
            
            JOptionPane.showMessageDialog(this,
                "Settings saved successfully to " + envFile.getAbsolutePath() + "\n" +
                "Environment variables have been reloaded.",
                "Settings Saved",
                JOptionPane.INFORMATION_MESSAGE);
            
            dispose();
            
        } catch (Exception e) {
            JOptionPane.showMessageDialog(this,
                "Error saving settings: " + e.getMessage(),
                "Save Error",
                JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void resetToAutoDetected() {
        int result = JOptionPane.showConfirmDialog(this,
            "This will reset all paths to auto-detected values.\n" +
            "Any custom paths you've entered will be lost.\n\n" +
            "Continue?",
            "Reset to Auto-Detected",
            JOptionPane.YES_NO_OPTION,
            JOptionPane.WARNING_MESSAGE);
        
        if (result == JOptionPane.YES_OPTION) {
            // Clear all fields to trigger auto-detection
            for (JTextField field : pathFields.values()) {
                field.setText("");
            }
            
            // Force reload with auto-detection
            EnvLoader.clearAndReload();
            
            // Reload the auto-detected values
            loadCurrentSettings();
            
            settingsChanged = true;
            
            JOptionPane.showMessageDialog(this,
                "All paths have been reset to auto-detected values.\n" +
                "You can now review and modify them as needed.",
                "Reset Complete",
                JOptionPane.INFORMATION_MESSAGE);
        }
    }
}
