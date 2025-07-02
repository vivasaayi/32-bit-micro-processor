package tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import javax.swing.SwingWorker;
import util.AppState;

public class JavaTab extends BaseTab {
    private JTextArea sourceArea;
    private JTextArea bytecodeArea;
    private JTextArea explanationArea;
    private JTextArea logArea;
    private JButton compileButton;
    private JButton explainButton;
    private JTabbedPane innerTabs;
    
    public JavaTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Source code area
        sourceArea = new JTextArea();
        sourceArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        sourceArea.setTabSize(4);
        
        // Bytecode area
        bytecodeArea = new JTextArea();
        bytecodeArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        bytecodeArea.setEditable(false);
        bytecodeArea.setBackground(new Color(245, 245, 245));
        
        // Explanation area
        explanationArea = new JTextArea();
        explanationArea.setFont(new Font(Font.SANS_SERIF, Font.PLAIN, 12));
        explanationArea.setEditable(false);
        explanationArea.setLineWrap(true);
        explanationArea.setWrapStyleWord(true);
        explanationArea.setBackground(new Color(250, 250, 240));
        
        // Log area
        logArea = new JTextArea(8, 0);
        logArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 10));
        logArea.setEditable(false);
        logArea.setBackground(Color.BLACK);
        logArea.setForeground(Color.WHITE);
        
        // Buttons
        compileButton = new JButton("Compile Java");
        compileButton.addActionListener(e -> compileJava());
        
        explainButton = new JButton("Explain Bytecode");
        explainButton.addActionListener(e -> explainBytecode());
        explainButton.setEnabled(false);
        
        // Create inner tabs
        innerTabs = new JTabbedPane();
        
        // Source code tab with compile button
        JPanel sourcePanel = new JPanel(new BorderLayout());
        JPanel sourceButtonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        sourceButtonPanel.add(compileButton);
        sourcePanel.add(new JScrollPane(sourceArea), BorderLayout.CENTER);
        sourcePanel.add(sourceButtonPanel, BorderLayout.SOUTH);
        
        // Bytecode tab with explain button
        JPanel bytecodePanel = new JPanel(new BorderLayout());
        JPanel bytecodeButtonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        bytecodeButtonPanel.add(explainButton);
        bytecodePanel.add(new JScrollPane(bytecodeArea), BorderLayout.CENTER);
        bytecodePanel.add(bytecodeButtonPanel, BorderLayout.SOUTH);
        
        innerTabs.addTab("Source Code", sourcePanel);
        innerTabs.addTab("Bytecode", bytecodePanel);
        innerTabs.addTab("Explanation", new JScrollPane(explanationArea));
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // Split pane: tabs on top, log on bottom
        JSplitPane splitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, innerTabs, new JScrollPane(logArea));
        splitPane.setDividerLocation(500);
        splitPane.setResizeWeight(0.8);
        
        add(splitPane, BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        sourceArea.setText(content);
        bytecodeArea.setText("");
        explanationArea.setText("");
        logArea.setText("");
        explainButton.setEnabled(false);
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
    
    @Override
    public void clearContent() {
        if (sourceArea != null) sourceArea.setText("");
        if (bytecodeArea != null) bytecodeArea.setText("");
        if (explanationArea != null) explanationArea.setText("");
        if (logArea != null) logArea.setText("");
    }
    
    private void compileJava() {
        if (appState.getCurrentFile() == null) {
            showError("Compile Error", "No file selected");
            return;
        }
        
        saveContent();
        
        compileButton.setEnabled(false);
        appState.setCompiling(true);
        updateStatus("Compiling Java...");
        logArea.setText("Starting Java compilation...\n");
        
        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    File sourceFile = appState.getCurrentFile();
                    File parentDir = sourceFile.getParentFile();
                    
                    // Compile with javac
                    ProcessBuilder pb = new ProcessBuilder("javac", sourceFile.getName());
                    pb.directory(parentDir);
                    
                    Process process = pb.start();
                    
                    // Read stdout and stderr
                    readProcessOutput(process, "JAVAC");
                    
                    int exitCode = process.waitFor();
                    if (exitCode == 0) {
                        publish("Java compilation successful!");
                        
                        // Generate bytecode with javap
                        String className = sourceFile.getName().replace(".java", "");
                        ProcessBuilder javapPb = new ProcessBuilder("javap", "-c", "-p", className);
                        javapPb.directory(parentDir);
                        
                        Process javapProcess = javapPb.start();
                        
                        // Capture bytecode output
                        StringBuilder bytecodeOutput = new StringBuilder();
                        try (BufferedReader reader = new BufferedReader(new InputStreamReader(javapProcess.getInputStream()))) {
                            String line;
                            while ((line = reader.readLine()) != null) {
                                bytecodeOutput.append(line).append("\n");
                            }
                        }
                        
                        int javapExitCode = javapProcess.waitFor();
                        if (javapExitCode == 0) {
                            final String bytecode = bytecodeOutput.toString();
                            SwingUtilities.invokeLater(() -> {
                                bytecodeArea.setText(bytecode);
                                explainButton.setEnabled(true);
                                innerTabs.setSelectedIndex(1); // Switch to bytecode tab
                            });
                            publish("Bytecode extraction successful!");
                        } else {
                            publish("Failed to extract bytecode");
                        }
                        
                    } else {
                        publish("Java compilation failed with exit code: " + exitCode);
                    }
                    
                } catch (Exception e) {
                    publish("Compilation error: " + e.getMessage());
                }
                
                return null;
            }
            
            private void readProcessOutput(Process process, String prefix) throws IOException {
                // Read stdout
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        publish(prefix + " STDOUT: " + line);
                    }
                }
                
                // Read stderr
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        publish(prefix + " STDERR: " + line);
                    }
                }
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
                compileButton.setEnabled(true);
                appState.setCompiling(false);
                updateStatus("Java compilation complete");
            }
        };
        
        worker.execute();
    }
    
    private void explainBytecode() {
        String bytecode = bytecodeArea.getText();
        if (bytecode.isEmpty()) {
            showInfo("No Bytecode", "Please compile the Java code first to generate bytecode.");
            return;
        }
        
        explainButton.setEnabled(false);
        updateStatus("Explaining bytecode...");
        
        SwingWorker<String, Void> worker = new SwingWorker<String, Void>() {
            @Override
            protected String doInBackground() throws Exception {
                // Simple bytecode explanation - can be enhanced with LLM integration
                return generateBytecodeExplanation(bytecode);
            }
            
            @Override
            protected void done() {
                try {
                    String explanation = get();
                    explanationArea.setText(explanation);
                    innerTabs.setSelectedIndex(2); // Switch to explanation tab
                    updateStatus("Bytecode explanation complete");
                } catch (Exception e) {
                    showError("Explanation Error", "Failed to explain bytecode: " + e.getMessage());
                }
                explainButton.setEnabled(true);
            }
        };
        
        worker.execute();
    }
    
    private String generateBytecodeExplanation(String bytecode) {
        StringBuilder explanation = new StringBuilder();
        explanation.append("JAVA BYTECODE EXPLANATION\n");
        explanation.append("========================\n\n");
        
        String[] lines = bytecode.split("\n");
        
        for (String line : lines) {
            line = line.trim();
            
            if (line.contains(":")) {
                // Bytecode instruction line
                explanation.append("Instruction: ").append(line).append("\n");
                
                // Basic instruction explanations
                if (line.contains("iconst")) {
                    explanation.append("  → Pushes integer constant onto stack\n");
                } else if (line.contains("istore")) {
                    explanation.append("  → Stores integer from stack to local variable\n");
                } else if (line.contains("iload")) {
                    explanation.append("  → Loads integer from local variable onto stack\n");
                } else if (line.contains("iadd")) {
                    explanation.append("  → Adds two integers from stack\n");
                } else if (line.contains("isub")) {
                    explanation.append("  → Subtracts two integers from stack\n");
                } else if (line.contains("imul")) {
                    explanation.append("  → Multiplies two integers from stack\n");
                } else if (line.contains("idiv")) {
                    explanation.append("  → Divides two integers from stack\n");
                } else if (line.contains("return")) {
                    explanation.append("  → Returns from method\n");
                } else if (line.contains("invoke")) {
                    explanation.append("  → Invokes a method\n");
                } else if (line.contains("getfield")) {
                    explanation.append("  → Gets field value from object\n");
                } else if (line.contains("putfield")) {
                    explanation.append("  → Sets field value in object\n");
                }
                explanation.append("\n");
            }
        }
        
        explanation.append("\nNOTE: This is a basic explanation. For advanced bytecode analysis,\n");
        explanation.append("consider integrating with a local LLM or ASM bytecode library.\n");
        
        return explanation.toString();
    }
}
