package tabs;

import javax.swing.*;
import java.awt.*;
import util.AppState;

public class SimulationLogTab extends BaseTab {
    private JTextArea logArea;
    
    public SimulationLogTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        logArea = new JTextArea();
        logArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 11));
        logArea.setEditable(false);
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        add(new JScrollPane(logArea), BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        logArea.setText(content);
    }
    
    @Override
    public void saveContent() {
        // Logs are read-only
    }
    
    @Override
    public void clearContent() {
        // Simulation logs are typically not cleared manually
    }
}
