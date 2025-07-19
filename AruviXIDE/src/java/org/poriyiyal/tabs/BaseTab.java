package org.poriyiyal.tabs;

import javax.swing.*;

import org.poriyiyal.util.AppState;

/**
 * Base class for all IDE tabs
 */
public abstract class BaseTab extends JPanel {
    protected AppState appState;
    protected JFrame parentFrame;
    
    public BaseTab(AppState appState, JFrame parentFrame) {
        this.appState = appState;
        this.parentFrame = parentFrame;
        initializeComponents();
        setupLayout();
    }
    
    protected abstract void initializeComponents();
    protected abstract void setupLayout();
    
    public abstract void loadContent(String content);
    public abstract void saveContent();
    
    /**
     * Clear content of this tab (called when new file is selected)
     */
    public void clearContent() {
        // Override in subclasses to clear specific content
    }
    
    protected void updateStatus(String message) {
        // Update status through parent frame using reflection to avoid circular imports
        try {
            java.lang.reflect.Method method = parentFrame.getClass().getMethod("updateStatus", String.class);
            method.invoke(parentFrame, message);
        } catch (Exception e) {
            // If updateStatus method not found, silently ignore
            System.out.println("Status: " + message);
        }
    }
    
    protected void showError(String title, String message) {
        JOptionPane.showMessageDialog(this, message, title, JOptionPane.ERROR_MESSAGE);
    }
    
    protected void showInfo(String title, String message) {
        JOptionPane.showMessageDialog(this, message, title, JOptionPane.INFORMATION_MESSAGE);
    }
}
