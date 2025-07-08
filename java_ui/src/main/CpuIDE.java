package main;

import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.KeyEvent;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import tabs.*;
import util.AppState;
import util.FileWatcher;

/**
 * Main IDE Application for Custom CPU Development
 * Supports C, Java, Assembly, Verilog development and simulation
 */
public class CpuIDE extends JFrame {
    private static final String TITLE = "Custom CPU IDE";
    private static final String TEST_PROGRAMS_PATH = "/Users/rajanpanneerselvam/work/hdl/test_programs";
    
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
        
        // Add tabs to tabbed pane
        tabbedPane.addTab("C", cTab);
        tabbedPane.addTab("Java", javaTab);
        tabbedPane.addTab("Assembly", assemblyTab);
        tabbedPane.addTab("Hex", hexTab);
        tabbedPane.addTab("Testbench Template", testbenchTemplateTab);
        tabbedPane.addTab("V/VVP", vvpTab);
        tabbedPane.addTab("Simulation", simulationTab); // Add after V/VVP
        tabbedPane.addTab("Sim Log", simulationLogTab);
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
        
        JMenuItem exitItem = new JMenuItem("Exit");
        exitItem.setMnemonic(KeyEvent.VK_X);
        exitItem.addActionListener(_ -> System.exit(0));
        
        fileMenu.add(openItem);
        fileMenu.add(saveItem);
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
        
        menuBar.add(fileMenu);
        menuBar.add(toolsMenu);
        
        setJMenuBar(menuBar);
    }
    
    private void setupKeyboardShortcuts() {
        // Tab switching shortcuts (Ctrl+1 through Ctrl+8)
        for (int i = 1; i <= 8; i++) {
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
        tabbedPane.setEnabledAt(4, true); // Testbench Template tab (always visible)
        tabbedPane.setEnabledAt(5, true); // V/VVP tab (always enabled now)
        tabbedPane.setEnabledAt(6, true); // Simulation tab (always enabled)
        tabbedPane.setEnabledAt(7, true); // Sim Log tab
        tabbedPane.setEnabledAt(8, true); // Terminal tab
        tabbedPane.setEnabledAt(9, true); // VCD tab
        
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
                    tabbedPane.setEnabledAt(5, true); // V/VVP tab
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
            tabbedPane.setEnabledAt(5, true); // V/VVP tab
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
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            // Use default look and feel
            new CpuIDE().setVisible(true);
        });
    }
}
