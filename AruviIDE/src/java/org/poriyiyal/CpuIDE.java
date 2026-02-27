package org.poriyiyal;

import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import org.poriyiyal.tabs.*;
import org.poriyiyal.tabs.*;
import org.poriyiyal.util.AppState;
import org.poriyiyal.util.FileWatcher;
import org.poriyiyal.dialogs.SettingsDialog;

/**
 * Main IDE Application for Custom CPU Development
 * Supports C, Java, Assembly, Verilog development and simulation
 */
public class CpuIDE extends JFrame {
    private static final String TITLE = "Custom CPU IDE";
    private static final String TEST_PROGRAMS_PATH = "../test_programs";
    
    // UI Components
    private JTabbedPane tabbedPane;
    private JLabel statusLabel;
    private JMenuBar menuBar;
    
    // Tab instances
    private CTab cTab;
    private JavaTab javaTab;
    private AssemblyTab assemblyTab;
    private HexTab hexTab;
    private TestbenchTemplateTab testbenchTemplateTab;
    private VVvpTab vvpTab;
    private SimulationLogTab simulationLogTab;
    private TerminalTab terminalTab;
    private VcdTab vcdTab;
    private SimulationTab simulationTab;
    private InstructionDecoderTab instructionDecoderTab;
    private OpcodeEncoderTab opcodeEncoderTab;
    private FramebufferTab framebufferTab;
    
    // Application state
    private AppState appState;
    private FileWatcher fileWatcher;
    
    public CpuIDE() {
        initializeComponents();
        setupLayout();
        setupMenuBar();
        setupKeyboardShortcuts();
        setupFileWatcher();
        
        // Initialize with all tabs disabled except always-visible ones
        updateTabStates(null);
        
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(1400, 900);
        setLocationRelativeTo(null);
        setTitle(TITLE);
    }
    
    private void initializeComponents() {
        appState = new AppState();
        
        // Create tabbed pane
        tabbedPane = new JTabbedPane();
        
        // Initialize all tabs
        cTab = new CTab(appState, this);
        javaTab = new JavaTab(appState, this);
        assemblyTab = new AssemblyTab(appState, this);
        hexTab = new HexTab(appState, this);
        testbenchTemplateTab = new TestbenchTemplateTab(appState, this);
        vvpTab = new VVvpTab(appState, this);
        simulationLogTab = new SimulationLogTab(appState, this);
        terminalTab = new TerminalTab(appState, this);
        vcdTab = new VcdTab(appState, this);
        simulationTab = new SimulationTab(appState, this);
        instructionDecoderTab = new InstructionDecoderTab(appState, this);
        opcodeEncoderTab = new OpcodeEncoderTab(appState, this);
        framebufferTab = new FramebufferTab(appState, this);
        
        // Add tabs to tabbed pane
        tabbedPane.addTab("C", cTab);
        tabbedPane.addTab("Java", javaTab);
        tabbedPane.addTab("Assembly", assemblyTab);
        tabbedPane.addTab("Hex", hexTab);
        tabbedPane.addTab("Instruction Decoder", instructionDecoderTab);
        tabbedPane.addTab("Opcode Encoder", opcodeEncoderTab);
        tabbedPane.addTab("Testbench Template", testbenchTemplateTab);
        tabbedPane.addTab("V/VVP", vvpTab);
        tabbedPane.addTab("Simulation", simulationTab); // Add after V/VVP
        tabbedPane.addTab("Sim Log", simulationLogTab);
        tabbedPane.addTab("Framebuffer", framebufferTab);
        tabbedPane.addTab("Terminal", terminalTab);
        tabbedPane.addTab("VCD", vcdTab);
        
        // Status bar
        statusLabel = new JLabel("Ready");
        statusLabel.setBorder(BorderFactory.createLoweredBevelBorder());
        statusLabel.setPreferredSize(new Dimension(0, 25));
    }
    
    private void setupLayout() {
        setLayout(new BorderLayout());
        add(tabbedPane, BorderLayout.CENTER);
        add(statusLabel, BorderLayout.SOUTH);
    }
    
    private void setupMenuBar() {
        menuBar = new JMenuBar();
        
        // File menu
        JMenu fileMenu = new JMenu("File");
        fileMenu.setMnemonic(KeyEvent.VK_F);
        
        JMenuItem openItem = new JMenuItem("Open...");
        openItem.setMnemonic(KeyEvent.VK_O);
        openItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, KeyEvent.CTRL_DOWN_MASK));
        openItem.addActionListener(_ -> openFile());
        
        JMenuItem saveItem = new JMenuItem("Save");
        saveItem.setMnemonic(KeyEvent.VK_S);
        saveItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, KeyEvent.CTRL_DOWN_MASK));
        saveItem.addActionListener(_ -> saveCurrentFile());
        
        JMenuItem settingsItem = new JMenuItem("Settings...");
        settingsItem.setMnemonic(KeyEvent.VK_T);
        settingsItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_COMMA, KeyEvent.CTRL_DOWN_MASK));
        settingsItem.addActionListener(_ -> openSettings());
        
        JMenuItem exitItem = new JMenuItem("Exit");
        exitItem.setMnemonic(KeyEvent.VK_X);
        exitItem.addActionListener(_ -> System.exit(0));
        
        fileMenu.add(openItem);
        fileMenu.add(saveItem);
        fileMenu.addSeparator();
        fileMenu.add(settingsItem);
        fileMenu.addSeparator();
        fileMenu.add(exitItem);
        
        // Tools menu
        JMenu toolsMenu = new JMenu("Tools");
        toolsMenu.setMnemonic(KeyEvent.VK_T);
        
        JMenuItem runSimItem = new JMenuItem("Run Simulation");
        runSimItem.setMnemonic(KeyEvent.VK_R);
        runSimItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_R, KeyEvent.CTRL_DOWN_MASK));
        runSimItem.addActionListener(_ -> runSimulation());
        
        toolsMenu.add(runSimItem);
        
        // Help menu
        JMenu helpMenu = new JMenu("Help");
        helpMenu.setMnemonic(KeyEvent.VK_H);
        
        JMenuItem shortcutsItem = new JMenuItem("Keyboard Shortcuts");
        shortcutsItem.setMnemonic(KeyEvent.VK_K);
        shortcutsItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F1, 0));
        shortcutsItem.addActionListener(_ -> showKeyboardShortcuts());
        
        helpMenu.add(shortcutsItem);
        
        menuBar.add(fileMenu);
        menuBar.add(toolsMenu);
        menuBar.add(helpMenu);
        
        setJMenuBar(menuBar);
    }
    
    private void setupKeyboardShortcuts() {
        // Tab switching shortcuts (Ctrl+1 through Ctrl+9, then Ctrl+0 for tab 10)
        for (int i = 1; i <= 9; i++) {
            final int tabIndex = i - 1;
            KeyStroke keyStroke = KeyStroke.getKeyStroke(KeyEvent.VK_0 + i, KeyEvent.CTRL_DOWN_MASK);
            getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(keyStroke, "selectTab" + i);
            getRootPane().getActionMap().put("selectTab" + i, new AbstractAction() {
                @Override
                public void actionPerformed(ActionEvent e) {
                    if (tabIndex < tabbedPane.getTabCount()) {
                        tabbedPane.setSelectedIndex(tabIndex);
                    }
                }
            });
        }
        
        // Ctrl+0 for tab 10 (Sim Log), Ctrl+- for tab 11 (Framebuffer), Ctrl+= for tab 12 (Terminal), Ctrl+Backspace for tab 13 (VCD)
        KeyStroke ctrl0 = KeyStroke.getKeyStroke(KeyEvent.VK_0, KeyEvent.CTRL_DOWN_MASK);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(ctrl0, "selectTab10");
        getRootPane().getActionMap().put("selectTab10", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (9 < tabbedPane.getTabCount()) {
                    tabbedPane.setSelectedIndex(9); // Sim Log
                }
            }
        });
        
        KeyStroke ctrlMinus = KeyStroke.getKeyStroke(KeyEvent.VK_MINUS, KeyEvent.CTRL_DOWN_MASK);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(ctrlMinus, "selectTab11");
        getRootPane().getActionMap().put("selectTab11", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (10 < tabbedPane.getTabCount()) {
                    tabbedPane.setSelectedIndex(10); // Framebuffer
                }
            }
        });
        
        KeyStroke ctrlEquals = KeyStroke.getKeyStroke(KeyEvent.VK_EQUALS, KeyEvent.CTRL_DOWN_MASK);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(ctrlEquals, "selectTab12");
        getRootPane().getActionMap().put("selectTab12", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (11 < tabbedPane.getTabCount()) {
                    tabbedPane.setSelectedIndex(11); // Terminal
                }
            }
        });
        
        KeyStroke ctrlBackspace = KeyStroke.getKeyStroke(KeyEvent.VK_BACK_SPACE, KeyEvent.CTRL_DOWN_MASK);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(ctrlBackspace, "selectTab13");
        getRootPane().getActionMap().put("selectTab13", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (12 < tabbedPane.getTabCount()) {
                    tabbedPane.setSelectedIndex(12); // VCD
                }
            }
        });
        
        // Ctrl+Tab for next tab
        KeyStroke ctrlTab = KeyStroke.getKeyStroke(KeyEvent.VK_TAB, KeyEvent.CTRL_DOWN_MASK);
        getRootPane().getInputMap(JComponent.WHEN_IN_FOCUSED_WINDOW).put(ctrlTab, "nextTab");
        getRootPane().getActionMap().put("nextTab", new AbstractAction() {
            @Override
            public void actionPerformed(ActionEvent e) {
                int currentIndex = tabbedPane.getSelectedIndex();
                int nextIndex = (currentIndex + 1) % tabbedPane.getTabCount();
                tabbedPane.setSelectedIndex(nextIndex);
            }
        });
    }
    
    private void setupFileWatcher() {
        fileWatcher = new FileWatcher(appState, this);
        fileWatcher.start();
    }
    
    private void openFile() {
        JFileChooser fileChooser = new JFileChooser(TEST_PROGRAMS_PATH);
        
        // Set up file filters
        FileNameExtensionFilter filter = new FileNameExtensionFilter(
            "Supported Files", "c", "java", "asm", "hex", "v", "vvp", "log");
        fileChooser.setFileFilter(filter);
        
        int result = fileChooser.showOpenDialog(this);
        if (result == JFileChooser.APPROVE_OPTION) {
            File selectedFile = fileChooser.getSelectedFile();
            loadFile(selectedFile);
        }
    }
    
    public void loadFile(File file) {
        try {
            // Reset all tabs before loading new file
            resetAllTabStates();
            
            String content = new String(Files.readAllBytes(file.toPath()));
            String extension = getFileExtension(file.getName()).toLowerCase();
            
            appState.setCurrentFile(file);
            appState.setFileType(extension);
            
            // Update the appropriate tab based on file type
            switch (extension) {
                case "c":
                    cTab.loadContent(content);
                    tabbedPane.setSelectedComponent(cTab);
                    break;
                case "java":
                    javaTab.loadContent(content);
                    tabbedPane.setSelectedComponent(javaTab);
                    break;
                case "asm":
                    assemblyTab.loadContent(content);
                    tabbedPane.setSelectedComponent(assemblyTab);
                    break;
                case "hex":
                    hexTab.loadContent(content);
                    tabbedPane.setSelectedComponent(hexTab);
                    break;
                case "v":
                    vvpTab.loadVerilogContent(content);
                    tabbedPane.setSelectedComponent(vvpTab);
                    break;
                case "vvp":
                    vvpTab.loadVvpContent(content);
                    tabbedPane.setSelectedComponent(vvpTab);
                    break;
                case "log":
                    simulationLogTab.loadContent(content);
                    tabbedPane.setSelectedComponent(simulationLogTab);
                    break;
            }
            
            updateTabStates(extension);
            updateStatus("Loaded: " + file.getName());
            
        } catch (IOException e) {
            JOptionPane.showMessageDialog(this, 
                "Error loading file: " + e.getMessage(), 
                "File Error", 
                JOptionPane.ERROR_MESSAGE);
        }
    }
    
    private void updateTabStates(String fileType) {
        // Disable all tabs first
        for (int i = 0; i < tabbedPane.getTabCount(); i++) {
            tabbedPane.setEnabledAt(i, false);
        }
        
        // Always enable certain tabs
        tabbedPane.setEnabledAt(3, true); // Hex tab
        tabbedPane.setEnabledAt(4, true); // Instruction Decoder tab (always visible)
        tabbedPane.setEnabledAt(5, true); // Opcode Encoder tab (always visible)
        tabbedPane.setEnabledAt(6, true); // Testbench Template tab (always visible)
        tabbedPane.setEnabledAt(7, true); // V/VVP tab (always enabled now)
        tabbedPane.setEnabledAt(8, true); // Simulation tab (always enabled)
        tabbedPane.setEnabledAt(9, true); // Sim Log tab
        tabbedPane.setEnabledAt(10, true); // Framebuffer tab (always enabled)
        tabbedPane.setEnabledAt(11, true); // Terminal tab
        tabbedPane.setEnabledAt(12, true); // VCD tab
        
        // Enable tabs based on file type and generated files
        if (fileType != null) {
            switch (fileType) {
                case "c":
                    tabbedPane.setEnabledAt(0, true); // C tab
                    // Check if assembly was generated
                    if (appState.hasGeneratedFile("asm")) {
                        tabbedPane.setEnabledAt(2, true); // Assembly tab
                    }
                    break;
                case "java":
                    tabbedPane.setEnabledAt(1, true); // Java tab
                    break;
                case "asm":
                    tabbedPane.setEnabledAt(2, true); // Assembly tab
                    // Check if hex was generated
                    if (appState.hasGeneratedFile("hex")) {
                        // Hex tab is already enabled (always on)
                    }
                    break;
                case "hex":
                    // Enable assembly tab to allow going back to assembly from hex
                    tabbedPane.setEnabledAt(2, true); // Assembly tab
                    break;
                case "v":
                case "vvp":
                    tabbedPane.setEnabledAt(7, true); // V/VVP tab
                    break;
            }
        }
        
        // Additional enabling based on generated files regardless of original file type
        if (appState.hasGeneratedFile("asm")) {
            tabbedPane.setEnabledAt(2, true); // Assembly tab
        }
        if (appState.hasGeneratedFile("hex")) {
            // Hex tab is always enabled
        }
        if (appState.hasGeneratedFile("vvp")) {
            tabbedPane.setEnabledAt(7, true); // V/VVP tab
        }
    }
    
    private void saveCurrentFile() {
        // Implementation depends on which tab is active
        int selectedIndex = tabbedPane.getSelectedIndex();
        Component selectedTab = tabbedPane.getComponentAt(selectedIndex);
        
        if (selectedTab instanceof BaseTab) {
            ((BaseTab) selectedTab).saveContent();
        }
    }
    
    private void openSettings() {
        SettingsDialog settingsDialog = new SettingsDialog(this);
        settingsDialog.setVisible(true);
    }
    
    private void runSimulation() {
        // For now, just switch to the simulation log tab
        // The actual simulation will be run from the V/VVP tab
        tabbedPane.setSelectedComponent(simulationLogTab);
        updateStatus("Switch to V/VVP tab to run simulation");
    }
    
    public void updateStatus(String message) {
        SwingUtilities.invokeLater(() -> {
            statusLabel.setText(message);
        });
    }
    
    private String getFileExtension(String fileName) {
        int lastDotIndex = fileName.lastIndexOf('.');
        if (lastDotIndex > 0 && lastDotIndex < fileName.length() - 1) {
            return fileName.substring(lastDotIndex + 1);
        }
        return "";
    }
    
    /**
     * Called when C compilation generates an assembly file
     */
    public void loadGeneratedAssembly(File asmFile) {
        try {
            String content = new String(Files.readAllBytes(asmFile.toPath()));
            
            // Update app state to reflect the assembly file
            appState.setCurrentFile(asmFile);
            appState.setFileType("asm");
            
            assemblyTab.loadContent(content);
            
            // Enable assembly tab and switch to it
            tabbedPane.setEnabledAt(2, true); // Assembly tab
            tabbedPane.setSelectedComponent(assemblyTab);
            
            updateStatus("Generated assembly loaded: " + asmFile.getName());
        } catch (IOException e) {
            JOptionPane.showMessageDialog(this, 
                "Error loading generated assembly: " + e.getMessage(), 
                "File Error", 
                JOptionPane.ERROR_MESSAGE);
        }
    }
    
    /**
     * Called when Assembly compilation generates a hex file
     */
    public void loadGeneratedHex(File hexFile) {
        try {
            String content = new String(Files.readAllBytes(hexFile.toPath()));
            
            // Update app state to reflect the hex file
            appState.setCurrentFile(hexFile);
            appState.setFileType("hex");
            
            hexTab.loadContent(content);
            
            // Switch to hex tab (always enabled)
            tabbedPane.setSelectedComponent(hexTab);
            
            updateStatus("Generated hex loaded: " + hexFile.getName());
        } catch (IOException e) {
            JOptionPane.showMessageDialog(this, 
                "Error loading generated hex: " + e.getMessage(), 
                "File Error", 
                JOptionPane.ERROR_MESSAGE);
        }
    }
    
    /**
     * Called when Assembly compilation generates both hex and listing files
     */
    public void loadGeneratedHexWithListing(File hexFile, String listingContent) {
        try {
            String content = new String(Files.readAllBytes(hexFile.toPath()));
            
            // Update app state to reflect the hex file
            appState.setCurrentFile(hexFile);
            appState.setFileType("hex");
            
            // Load both hex content and listing
            hexTab.loadContent(content);
            hexTab.loadFromAssemblerListing(listingContent);
            
            // Switch to hex tab (always enabled)
            tabbedPane.setSelectedComponent(hexTab);
            
            updateStatus("Generated hex with listing loaded: " + hexFile.getName());
        } catch (IOException e) {
            JOptionPane.showMessageDialog(this, 
                "Error loading generated hex: " + e.getMessage(), 
                "File Error", 
                JOptionPane.ERROR_MESSAGE);
        }
    }
    
    /**
     * Reset all tabs when a new file is selected
     */
    private void resetAllTabStates() {
        // Clear content from all tabs
        if (cTab != null) cTab.clearContent();
        if (javaTab != null) javaTab.clearContent();
        if (assemblyTab != null) assemblyTab.clearContent();
        if (hexTab != null) hexTab.clearContent();
        if (testbenchTemplateTab != null) testbenchTemplateTab.clearContent();
        if (vvpTab != null) vvpTab.clearContent();
        if (simulationLogTab != null) simulationLogTab.clearContent();
        if (terminalTab != null) terminalTab.clearContent();
        if (vcdTab != null) vcdTab.clearContent();
        
        // Clear application state
        appState.clearGeneratedFiles();
    }
    
    // Getter methods for tab communication
    public TestbenchTemplateTab getTestbenchTemplateTab() {
        return testbenchTemplateTab;
    }
    
    public VVvpTab getVVvpTab() {
        return vvpTab;
    }
    
    public VcdTab getVcdTab() {
        return vcdTab;
    }
    
    public void switchToTab(String tabName) {
        for (int i = 0; i < tabbedPane.getTabCount(); i++) {
            if (tabbedPane.getTitleAt(i).equals(tabName)) {
                tabbedPane.setSelectedIndex(i);
                break;
            }
        }
    }
    
    public void showSimulationLog(String logContent) {
        simulationLogTab.loadContent(logContent);
        tabbedPane.setSelectedComponent(simulationLogTab);
        updateStatus("Simulation complete. See Sim Log tab.");
    }
    
    public void updateSimulationLogTab(String logContent) {
        simulationLogTab.loadContent(logContent);
        // Do not switch tabs
    }
    
    private void showKeyboardShortcuts() {
        String shortcutsText = """
            Custom CPU IDE - Keyboard Shortcuts
            
            Tab Navigation:
            Ctrl+1        C tab
            Ctrl+2        Java tab  
            Ctrl+3        Assembly tab
            Ctrl+4        Hex tab
            Ctrl+5        Instruction Decoder tab
            Ctrl+6        Opcode Encoder tab
            Ctrl+7        Testbench Template tab
            Ctrl+8        V/VVP tab
            Ctrl+9        Simulation tab
            Ctrl+0        Sim Log tab
            Ctrl+-        Framebuffer tab
            Ctrl+=        Terminal tab
            Ctrl+Backspace VCD tab
            
            Tab Cycling:
            Ctrl+Tab      Next tab
            Ctrl+Shift+Tab Previous tab
            
            File Operations:
            Ctrl+O        Open file
            Ctrl+S        Save current file
            
            Tools:
            Ctrl+R        Run simulation
            F1           Show this help
            """;
            
        JTextArea textArea = new JTextArea(shortcutsText);
        textArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        textArea.setEditable(false);
        textArea.setBackground(new Color(250, 250, 250));
        
        JScrollPane scrollPane = new JScrollPane(textArea);
        scrollPane.setPreferredSize(new Dimension(400, 500));
        
        JOptionPane.showMessageDialog(this, scrollPane, "Keyboard Shortcuts", JOptionPane.INFORMATION_MESSAGE);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            // Use default look and feel
            new CpuIDE().setVisible(true);
        });
    }
}
