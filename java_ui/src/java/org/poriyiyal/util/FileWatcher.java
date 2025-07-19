package org.poriyiyal.util;

import org.poriyiyal.CpuIDE;
import java.io.File;
import java.nio.file.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * File watcher for monitoring output files and reloading them automatically
 */
public class FileWatcher {
    private AppState appState;
    private CpuIDE ide;
    private ScheduledExecutorService executor;
    private WatchService watchService;
    
    public FileWatcher(AppState appState, CpuIDE ide) {
        this.appState = appState;
        this.ide = ide;
        this.executor = Executors.newSingleThreadScheduledExecutor();
    }
    
    public void start() {
        executor.scheduleAtFixedRate(this::checkForUpdates, 1, 1, TimeUnit.SECONDS);
    }
    
    public void stop() {
        if (executor != null) {
            executor.shutdown();
        }
    }
    
    private void checkForUpdates() {
        // Check for updated output files
        // This is a simple implementation - can be enhanced with proper file watching
        File currentFile = appState.getCurrentFile();
        if (currentFile != null) {
            // Check for related files that might have been updated
            checkRelatedFiles(currentFile);
        }
    }
    
    private void checkRelatedFiles(File sourceFile) {
        String baseName = getBaseName(sourceFile.getName());
        File parentDir = sourceFile.getParentFile();
        
        // Check for common output files
        checkAndNotify(new File(parentDir, baseName + ".hex"), "hex");
        checkAndNotify(new File(parentDir, baseName + ".asm"), "asm");
        checkAndNotify(new File(parentDir, baseName + ".log"), "log");
        checkAndNotify(new File(parentDir, "framebuffer.bin"), "framebuffer");
        checkAndNotify(new File(parentDir, "uart_output.txt"), "uart");
    }
    
    private void checkAndNotify(File file, String type) {
        if (file.exists()) {
            // Simple check - could be enhanced with proper modification time tracking
            appState.addGeneratedFile(type, file);
        }
    }
    
    private String getBaseName(String fileName) {
        int lastDotIndex = fileName.lastIndexOf('.');
        if (lastDotIndex > 0) {
            return fileName.substring(0, lastDotIndex);
        }
        return fileName;
    }
}
