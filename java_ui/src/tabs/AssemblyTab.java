package tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import javax.swing.SwingWorker;
import util.AppState;

public class AssemblyTab extends BaseTab {
    private JTextArea sourceArea;
    private JTextArea logArea;
    private JTextArea explanationArea;
    private JButton assembleButton;
    private JButton explainButton;
    private JLabel filePathLabel;
    private JSplitPane mainSplitPane;
    private JSplitPane rightSplitPane;
    
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
        updateFilePath();
    }
    
    @Override
    public void saveContent() {
        if (appState.getCurrentFile() != null) {
            try (FileWriter writer = new FileWriter(appState.getCurrentFile())) {
                writer.write(sourceArea.getText());
                updateStatus("Saved: " + appState.getCurrentFile().getName());
            } catch (IOException e) {
                showError("Save Error", "Failed to save file: " + e.getMessage());
            }
        }
    }
    
    public void loadFromCompilation(String assemblyContent) {
        // Called when C code is compiled to assembly
        loadContent(assemblyContent);
        updateStatus("Assembly loaded from C compilation");
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
                    
                    // Build assembler command - adjust path as needed
                    String assemblerPath = "/Users/rajanpanneerselvam/work/hdl/tools/assembler";
                    ProcessBuilder pb = new ProcessBuilder(assemblerPath, sourceFile.getAbsolutePath(), outputHex);
                    pb.directory(sourceFile.getParentFile());
                    
                    Process process = pb.start();
                    
                    // Read stdout
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
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
                        
                        // Notify parent to load hex tab
                        SwingUtilities.invokeLater(() -> {
                            try {
                                java.lang.reflect.Method method = parentFrame.getClass().getMethod("loadGeneratedHex", File.class);
                                method.invoke(parentFrame, hexFile);
                            } catch (Exception e) {
                                System.setProperty("generated.hex.file", hexFile.getAbsolutePath());
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
