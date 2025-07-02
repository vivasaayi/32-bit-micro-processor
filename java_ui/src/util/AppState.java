package util;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

/**
 * Central application state management
 */
public class AppState {
    private File currentFile;
    private String fileType;
    private Map<String, File> generatedFiles;
    private boolean isCompiling;
    private boolean isSimulating;
    
    public AppState() {
        this.generatedFiles = new HashMap<>();
        this.isCompiling = false;
        this.isSimulating = false;
    }
    
    // Getters and setters
    public File getCurrentFile() {
        return currentFile;
    }
    
    public void setCurrentFile(File currentFile) {
        this.currentFile = currentFile;
    }
    
    public String getFileType() {
        return fileType;
    }
    
    public void setFileType(String fileType) {
        this.fileType = fileType;
    }
    
    public Map<String, File> getGeneratedFiles() {
        return generatedFiles;
    }
    
    public void addGeneratedFile(String type, File file) {
        this.generatedFiles.put(type, file);
    }
    
    public File getGeneratedFile(String type) {
        return this.generatedFiles.get(type);
    }
    
    public boolean isCompiling() {
        return isCompiling;
    }
    
    public void setCompiling(boolean compiling) {
        isCompiling = compiling;
    }
    
    public boolean isSimulating() {
        return isSimulating;
    }
    
    public void setSimulating(boolean simulating) {
        isSimulating = simulating;
    }
    
    public String getCurrentStatus() {
        if (isCompiling) return "Compiling...";
        if (isSimulating) return "Simulating...";
        if (currentFile != null) return "Loaded: " + currentFile.getName();
        return "Ready";
    }
    
    /**
     * Clear all generated files
     */
    public void clearGeneratedFiles() {
        generatedFiles.clear();
    }
    
    /**
     * Check if a file type has been generated
     */
    public boolean hasGeneratedFile(String type) {
        return generatedFiles.containsKey(type);
    }
}
