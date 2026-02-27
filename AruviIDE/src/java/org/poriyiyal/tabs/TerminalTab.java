package org.poriyiyal.tabs;

import javax.swing.*;
import java.awt.*;
import org.poriyiyal.util.AppState;

public class TerminalTab extends BaseTab {
    private JTextArea terminalArea;
    
    public TerminalTab(AppState appState, JFrame parentFrame) {
        super(appState, parentFrame);
    }
    
    @Override
    protected void initializeComponents() {
        terminalArea = new JTextArea();
        terminalArea.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 12));
        terminalArea.setBackground(Color.BLACK);
        terminalArea.setForeground(Color.GREEN);
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        add(new JScrollPane(terminalArea), BorderLayout.CENTER);
    }
    
    @Override
    public void loadContent(String content) {
        terminalArea.setText(content);
    }
    
    @Override
    public void saveContent() {
        // Terminal output is read-only
    }
    
    @Override
    public void clearContent() {
        // Terminal content is typically persistent
    }
}
