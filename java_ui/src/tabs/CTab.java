package tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import javax.swing.SwingWorker;
import util.AppState;

/**
 * C Tab for editing and compiling C source code
 */
public class CTab extends BaseTab {
    private JTextArea sourceArea;
    private JTextArea logArea;
    private JButton compileButton;
    private JLabel filePathLabel;
    private JSplitPane splitPane;
    
    public CTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        // Source code area
        sourceArea = new JTextArea();
        sourceArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        sourceArea.setTabSize(4);
        
        // Log area
        logArea = new JTextArea(10, 0);
        logArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        logArea.setEditable(false);
        logArea.setBackground(Color.BLACK);
        logArea.setForeground(Color.WHITE);
        
        // Compile button
        compileButton = new JButton("Compile");
        compileButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                compileCode();
            }
        });
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // File path label at the top
        filePathLabel = new JLabel("No file loaded");
        filePathLabel.setFont(new Font(Font.SANS_SERIF, Font.ITALIC, 10));
        filePathLabel.setForeground(Color.BLUE);
        filePathLabel.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));
        filePathLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openFileLocation();
            }
        });
        add(filePathLabel, BorderLayout.NORTH);
        
        // Top panel with source code
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.add(new JScrollPane(sourceArea), BorderLayout.CENTER);
        
        // Button panel
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        buttonPanel.add(compileButton);
        topPanel.add(buttonPanel, BorderLayout.SOUTH);
        
        // Bottom panel with log
        JPanel bottomPanel = new JPanel(new BorderLayout());
        bottomPanel.add(new JLabel("Compilation Log:"), BorderLayout.NORTH);
        bottomPanel.add(new JScrollPane(logArea), BorderLayout.CENTER);
        
        // Split pane
        splitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT, topPanel, bottomPanel);
        splitPane.setDividerLocation(400);
        splitPane.setResizeWeight(0.7);
        
        add(splitPane, BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        sourceArea.setText(content);
        logArea.setText("");
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
    
    @Override
    public void clearContent() {
        if (sourceArea != null) sourceArea.setText("");
        if (logArea != null) logArea.setText("");
    }
    
    private void compileCode() {
        if (appState.getCurrentFile() == null) {
            showError("Compile Error", "No file selected");
            return;
        }
        
        // Save current content first
        saveContent();
        
        compileButton.setEnabled(false);
        appState.setCompiling(true);
        updateStatus("Compiling...");
        logArea.setText("Starting compilation...\n");
        
        SwingWorker<Void, String> worker = new SwingWorker<Void, String>() {
            @Override
            protected Void doInBackground() throws Exception {
                try {
                    // Build compiler command with file-based naming
                    String compilerPath = "/Users/rajanpanneerselvam/work/hdl/compiler/ccompiler";
                    String inputFile = appState.getCurrentFile().getAbsolutePath();
                    
                    // Generate output file name based on input file
                    File inputFileObj = new File(inputFile);
                    String baseName = inputFileObj.getName();
                    if (baseName.contains(".")) {
                        baseName = baseName.substring(0, baseName.lastIndexOf('.'));
                    }
                    String outputFile = new File(inputFileObj.getParent(), baseName + ".s").getAbsolutePath();
                    
                    ProcessBuilder pb = new ProcessBuilder(compilerPath, inputFile, "-o", outputFile);
                    pb.directory(inputFileObj.getParentFile());
                    
                    Process process = pb.start();
                    
                    // Read stdout
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("STDOUT: " + line);
                        }
                    }
                    
                    // Read stderr
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            publish("STDERR: " + line);
                        }
                    }
                    
                    int exitCode = process.waitFor();
                    if (exitCode == 0) {
                        publish("Compilation successful!");
                        File asmFile = new File(outputFile);
                        
                        // Check if output.s actually exists
                        if (asmFile.exists()) {
                            appState.addGeneratedFile("asm", asmFile);
                            
                            // Notify parent to enable and load assembly tab
                            SwingUtilities.invokeLater(() -> {
                                // Use reflection to call loadGeneratedAssembly if it exists
                                try {
                                    java.lang.reflect.Method method = parentFrame.getClass().getMethod("loadGeneratedAssembly", File.class);
                                    method.invoke(parentFrame, asmFile);
                                } catch (Exception e) {
                                    // Fallback: set a system property that the main IDE can check
                                    System.setProperty("generated.assembly.file", asmFile.getAbsolutePath());
                                }
                            });
                        } else {
                            publish("Warning: Expected output file not found: " + outputFile);
                        }
                    } else {
                        publish("Compilation failed with exit code: " + exitCode);
                    }
                    
                } catch (Exception e) {
                    publish("Compilation error: " + e.getMessage());
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
                compileButton.setEnabled(true);
                appState.setCompiling(false);
                updateStatus("Compilation complete");
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
    
    public void updateFilePath() {
        if (appState.getCurrentFile() != null) {
            filePathLabel.setText("File: " + appState.getCurrentFile().getAbsolutePath());
        } else {
            filePathLabel.setText("No file loaded");
        }
    }
}
