package org.poriyiyal.tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.io.*;
import javax.swing.SwingWorker;
import org.poriyiyal.util.AppState;

public class AssemblyTab extends BaseTab {
    private JTextArea sourceArea;
    private JTextArea logArea;
    private JTextArea explanationArea;
    private JButton assembleButton;
    private JButton explainButton;
    private JLabel filePathLabel;
    private JSplitPane mainSplitPane;
    private JSplitPane rightSplitPane;
    private JButton saveButton;
    private JButton reloadButton;
    // Track the last loaded .asm file for reload
    private File lastAsmFile = null;
    
    public AssemblyTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Assembly source area
        sourceArea = new JTextArea();
        sourceArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        sourceArea.setTabSize(8);
        
        // Log area
        logArea = new JTextArea();
        logArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        logArea.setEditable(false);
        logArea.setBackground(Color.BLACK);
        logArea.setForeground(Color.WHITE);
        
        // Explanation area
        explanationArea = new JTextArea();
        explanationArea.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 12));
        explanationArea.setEditable(false);
        explanationArea.setLineWrap(true);
        explanationArea.setWrapStyleWord(true);
        explanationArea.setBackground(new Color(240, 248, 255));
        
        // Buttons
        assembleButton = new JButton("Assemble to Hex");
        assembleButton.addActionListener(e -> assembleCode());
        
        explainButton = new JButton("Explain Assembly");
        explainButton.addActionListener(e -> explainAssembly());
        
        // Save button
        JButton saveButton = new JButton("Save");
        saveButton.setToolTipText("Save (Ctrl+S)");
        saveButton.addActionListener(e -> saveContent());
        this.saveButton = saveButton;
        
        // Reload button
        reloadButton = new JButton("Reload");
        reloadButton.setToolTipText("Reload file from disk");
        reloadButton.addActionListener(e -> reloadFile());
        
        // Keyboard shortcut for save (Ctrl+S)
        sourceArea.getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(KeyStroke.getKeyStroke("control S"), "saveFile");
        sourceArea.getActionMap().put("saveFile", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                saveContent();
            }
        });
    }

    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // File path label at the top
        filePathLabel = new JLabel("No assembly file loaded");
        filePathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        filePathLabel.setForeground(Color.BLUE);
        filePathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        filePathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openFileLocation();
            }
        });
        add(filePathLabel, BorderLayout.NORTH);
        
        // Left panel: source code with buttons
        JPanel leftPanel = new JPanel(new BorderLayout());
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(saveButton);
        buttonPanel.add(reloadButton);
        buttonPanel.add(assembleButton);
        buttonPanel.add(explainButton);
        
        leftPanel.add(new JScrollPane(sourceArea), BorderLayout.CENTER);
        leftPanel.add(buttonPanel, BorderLayout.SOUTH);
        
        // Right panel: split between log and explanation
        rightSplitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT);
        rightSplitPane.setTopComponent(new JScrollPane(logArea));
        rightSplitPane.setBottomComponent(new JScrollPane(explanationArea));
        rightSplitPane.setDividerLocation(200);
        
        // Main split pane
        mainSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, leftPanel, rightSplitPane);
        mainSplitPane.setDividerLocation(600);
        mainSplitPane.setResizeWeight(0.6);
        
        add(mainSplitPane, BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        sourceArea.setText(content);
        logArea.setText("");
        explanationArea.setText("");
        // Only update lastAsmFile if the current file is an .asm
        File file = appState.getCurrentFile();
        if (file != null && file.getName().endsWith(".asm")) {
            lastAsmFile = file;
        }
        updateFilePath();
    }
    
    @Override
    public void saveContent() {
        File file = appState.getCurrentFile();
        if (file != null) {
            try (FileWriter writer = new FileWriter(file)) {
                writer.write(sourceArea.getText());
                updateStatus("Saved: " + file.getName());
                updateFilePath();
            } catch (IOException e) {
                showError("Save Error", "Failed to save file: " + e.getMessage());
            }
        } else {
            showError("No File Loaded", "No file is loaded. Please open or create a file first.");
        }
    }
    
    private void reloadFile() {
        File file = lastAsmFile;
        if (file != null && file.exists()) {
            try {
                String content = new String(java.nio.file.Files.readAllBytes(file.toPath()));
                sourceArea.setText(content);
                logArea.setText("");
                explanationArea.setText("");
                updateStatus("Reloaded: " + file.getName());
                updateFilePath();
            } catch (IOException e) {
                showError("Reload Error", "Failed to reload file: " + e.getMessage());
            }
        } else {
            showError("No ASM File", "No .asm file loaded or file does not exist.");
        }
    }
    
    public void loadFromCompilation(String assemblyContent) {
        // Called when C code is compiled to assembly
        loadContent(assemblyContent);
        updateStatus("Assembly loaded from C compilation");
        // Do not update lastAsmFile here
    }
    
    private void assembleCode() {
        if (sourceArea.getText().trim().isEmpty()) {
            showError("Assembly Error", "No assembly code to assemble");
            return;
        }
        
        // Save current content first
        saveContent();
        
        assembleButton.setEnabled(false);
        updateStatus("Assembling...");
        logArea.setText("Starting assembly process...\n");
        
        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Create temporary assembly file if needed
                    File sourceFile = appState.getCurrentFile();
                    if (sourceFile == null || !sourceFile.getName().endsWith(".asm")) {
                        // Create temporary file
                        sourceFile = new File(System.getProperty("java.io.tmpdir"), "temp_assembly.asm");
                        try (FileWriter writer = new FileWriter(sourceFile)) {
                            writer.write(sourceArea.getText());
                        }
                    }
                    
                    String outputHex = sourceFile.getAbsolutePath().replace(".asm", ".hex");
                    
                    // Build assembler command with listing flag
                    String assemblerPath = "temp/assembler";
                    ProcessBuilder pb = new ProcessBuilder(assemblerPath, sourceFile.getAbsolutePath(), outputHex, "-l");
                    pb.directory(new File("/Users/rajanpanneerselvam/work/hdl"));
                    
                    Process process = pb.start();
                    
                    // Capture stdout (listing content) and stderr separately
                    StringBuilder listingContent = new StringBuilder();
                    
                    // Read stdout (listing content)
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            listingContent.append(line).append("\n");
                            publish("ASM STDOUT: " + line);
                        }
                    }
                    
                    // Read stderr
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("ASM STDERR: " + line);
                        }
                    }
                    
                    int exitCode = process.waitFor();
                    if (exitCode == 0) {
                        publish("Assembly successful! Generated: " + outputHex);
                        File hexFile = new File(outputHex);
                        appState.addGeneratedFile("hex", hexFile);
                        
                        // Capture the listing content for passing to HexTab
                        final String finalListingContent = listingContent.toString();
                        
                        // Notify parent to load hex tab with listing
                        SwingUtilities.invokeLater(() -> {
                            try {
                                // Try the new method with listing first
                                java.lang.reflect.Method method = parentFrame.getClass().getMethod("loadGeneratedHexWithListing", File.class, String.class);
                                method.invoke(parentFrame, hexFile, finalListingContent);
                            } catch (Exception e) {
                                // Fallback to old method if new one doesn't exist
                                try {
                                    java.lang.reflect.Method method = parentFrame.getClass().getMethod("loadGeneratedHex", File.class);
                                    method.invoke(parentFrame, hexFile);
                                } catch (Exception e2) {
                                    System.setProperty("generated.hex.file", hexFile.getAbsolutePath());
                                }
                            }
                        });
                    } else {
                        publish("Assembly failed with exit code: " + exitCode);
                    }
                    
                } catch (Exception e) {
                    publish("Assembly error: " + e.getMessage());
                }
                
                return null;
            }
            
            @Override
            protected void process(java.util.List<String> chunks) {
                for (String chunk : chunks) {
                    logArea.append(chunk + "\n");
                    logArea.setCaretPosition(logArea.getDocument().getLength());
                }
            }
            
            @Override
            protected void done() {
                assembleButton.setEnabled(true);
                updateStatus("Assembly complete");
            }
        };
        
        worker.execute();
    }
    
    private void explainAssembly() {
        String assembly = sourceArea.getText();
        if (assembly.trim().isEmpty()) {
            showInfo("No Assembly", "Please load or write assembly code first.");
            return;
        }
        
        explainButton.setEnabled(false);
        updateStatus("Explaining assembly...");
        
        SwingWorker<String, Void> worker = new SwingWorker<String, Void>() {
            @Override
            protected String doInBackground() throws Exception {
                return generateAssemblyExplanation(assembly);
            }
            
            @Override
            protected void done() {
                try {
                    String explanation = get();
                    explanationArea.setText(explanation);
                    updateStatus("Assembly explanation complete");
                } catch (Exception e) {
                    showError("Explanation Error", "Failed to explain assembly: " + e.getMessage());
                }
                explainButton.setEnabled(true);
            }
        };
        
        worker.execute();
    }
    
    private void openFileLocation() {
        try {
            if (appState.getCurrentFile() != null && appState.getCurrentFile().exists()) {
                File file = appState.getCurrentFile();
                // Open file location in Finder (macOS)
                if (System.getProperty("os.name").toLowerCase().contains("mac")) {
                    Runtime.getRuntime().exec(new String[]{"open", "-R", file.getAbsolutePath()});
                } else if (System.getProperty("os.name").toLowerCase().contains("windows")) {
                    Runtime.getRuntime().exec(new String[]{"explorer", "/select,", file.getAbsolutePath()});
                } else {
                    // Linux - open containing directory
                    Runtime.getRuntime().exec(new String[]{"xdg-open", file.getParent()});
                }
            }
        } catch (Exception e) {
            logArea.append("Error opening file location: " + e.getMessage() + "\n");
        }
    }
    
    private String generateAssemblyExplanation(String assembly) {
        StringBuilder explanation = new StringBuilder();
        explanation.append("ASSEMBLY CODE EXPLANATION\n");
        explanation.append("========================\n\n");
        
        String[] lines = assembly.split("\n");
        int lineNumber = 1;
        
        for (String line : lines) {
            String trimmedLine = line.trim();
            
            if (trimmedLine.isEmpty() || trimmedLine.startsWith(";")) {
                // Skip empty lines and comments
                lineNumber++;
                continue;
            }
            
            explanation.append("Line ").append(lineNumber).append(": ").append(trimmedLine).append("\n");
            
            // Basic instruction explanations
            String upperLine = trimmedLine.toUpperCase();
            
            if (upperLine.startsWith("LOADI")) {
                explanation.append("  → Load immediate value into register\n");
            } else if (upperLine.startsWith("LOAD")) {
                explanation.append("  → Load value from memory into register\n");
            } else if (upperLine.startsWith("STORE")) {
                explanation.append("  → Store register value to memory\n");
            } else if (upperLine.startsWith("ADD")) {
                explanation.append("  → Add two values\n");
            } else if (upperLine.startsWith("SUB")) {
                explanation.append("  → Subtract two values\n");
            } else if (upperLine.startsWith("MUL")) {
                explanation.append("  → Multiply two values\n");
            } else if (upperLine.startsWith("DIV")) {
                explanation.append("  → Divide two values\n");
            } else if (upperLine.startsWith("MOD")) {
                explanation.append("  → Modulo operation\n");
            } else if (upperLine.startsWith("AND")) {
                explanation.append("  → Bitwise AND operation\n");
            } else if (upperLine.startsWith("OR")) {
                explanation.append("  → Bitwise OR operation\n");
            } else if (upperLine.startsWith("XOR")) {
                explanation.append("  → Bitwise XOR operation\n");
            } else if (upperLine.startsWith("NOT")) {
                explanation.append("  → Bitwise NOT operation\n");
            } else if (upperLine.startsWith("SHL")) {
                explanation.append("  → Shift left operation\n");
            } else if (upperLine.startsWith("SHR")) {
                explanation.append("  → Shift right operation\n");
            } else if (upperLine.startsWith("CMP")) {
                explanation.append("  → Compare two values and set flags\n");
            } else if (upperLine.startsWith("JMP")) {
                explanation.append("  → Unconditional jump\n");
            } else if (upperLine.startsWith("JZ")) {
                explanation.append("  → Jump if zero flag is set\n");
            } else if (upperLine.startsWith("JNZ")) {
                explanation.append("  → Jump if zero flag is not set\n");
            } else if (upperLine.startsWith("HALT")) {
                explanation.append("  → Stop CPU execution\n");
            } else if (trimmedLine.endsWith(":")) {
                explanation.append("  → Label definition\n");
            } else {
                explanation.append("  → Custom instruction or data\n");
            }
            
            explanation.append("\n");
            lineNumber++;
        }
        
        explanation.append("\nNOTE: This is a basic explanation based on common assembly patterns.\n");
        explanation.append("For advanced analysis, consider integrating with a local LLM.\n");
        
        return explanation.toString();
    }
    
    @Override
    public void clearContent() {
        if (sourceArea != null) sourceArea.setText("");
        if (logArea != null) logArea.setText("");
        if (explanationArea != null) explanationArea.setText("");
    }
    
    public void updateFilePath() {
        if (appState.getCurrentFile() != null) {
            filePathLabel.setText("Assembly File: " + appState.getCurrentFile().getAbsolutePath());
        } else {
            filePathLabel.setText("No assembly file loaded");
        }
    }
}
