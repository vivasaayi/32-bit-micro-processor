package org.poriyiyal.util;

import java.io.*;
import java.util.Properties;

/**
 * Utility class to load environment variables from .env file
 */
public class EnvLoader {
    private static Properties envProperties = null;
    private static final String ENV_FILE_PATH = ".env";
    
    /**
     * Load environment variables from .env file
     */
    private static void loadEnvFile() {
        if (envProperties != null) {
            return; // Already loaded
        }
        
        envProperties = new Properties();
        
        try {
            // Try to find .env file in the current working directory or IDE directory
            File envFile = new File(ENV_FILE_PATH);
            if (!envFile.exists()) {
                // Try in the IDE source directory
                envFile = new File("AruviIDE/.env");
            }
            if (!envFile.exists()) {
                // Try relative to current directory
                envFile = new File("../.env");
            }
            
            if (envFile.exists()) {
                try (FileInputStream fis = new FileInputStream(envFile);
                     BufferedReader reader = new BufferedReader(new InputStreamReader(fis))) {
                    
                    String line;
                    while ((line = reader.readLine()) != null) {
                        line = line.trim();
                        // Skip comments and empty lines
                        if (line.isEmpty() || line.startsWith("#")) {
                            continue;
                        }
                        
                        // Parse key=value pairs
                        int equalsIndex = line.indexOf('=');
                        if (equalsIndex > 0) {
                            String key = line.substring(0, equalsIndex).trim();
                            String value = line.substring(equalsIndex + 1).trim();
                            envProperties.setProperty(key, value);
                        }
                    }
                }
                System.out.println("Loaded environment file: " + envFile.getAbsolutePath());
            } else {
                System.err.println("Warning: .env file not found. Using default values.");
                loadDefaultProperties();
            }
        } catch (IOException e) {
            System.err.println("Error loading .env file: " + e.getMessage());
            loadDefaultProperties();
        }
    }
    
    /**
     * Load default properties based on current working directory if .env file is not found
     */
    private static void loadDefaultProperties() {
        // Determine base directory from current working directory
        String currentDir = System.getProperty("user.dir");
        File workingDir = new File(currentDir);
        
        // Try to find the project root by looking for specific markers
        File projectRoot = findProjectRoot(workingDir);
        String baseDir = projectRoot.getAbsolutePath();
        
        // Look for common HDL directory patterns
        String hdlBaseDir = findHdlBaseDir(projectRoot);
        String tempDir = hdlBaseDir + "/temp";
        String processorDir = hdlBaseDir + "/processor";
        
        // Set default values based on discovered paths
        envProperties.setProperty("HDL_BASE_DIR", hdlBaseDir);
        envProperties.setProperty("TEMP_DIR", tempDir);
        envProperties.setProperty("PROCESSOR_BASE_DIR", processorDir);
        envProperties.setProperty("MICROPROCESSOR_SYSTEM_V", "../processor/microprocessor_system.v");
        envProperties.setProperty("CPU_CORE_V", "../processor/cpu/cpu_core.v");
        envProperties.setProperty("ALU_V", "../processor/cpu/alu.v");
        envProperties.setProperty("REGISTER_FILE_V", "../processor/cpu/register_file.v");
        envProperties.setProperty("MEMORY_CONTROLLER_V", processorDir + "/memory/memory_controller.v");
        envProperties.setProperty("MMU_V", processorDir + "/memory/mmu.v");
        envProperties.setProperty("UART_V", processorDir + "/io/uart.v");
        envProperties.setProperty("TIMER_V", processorDir + "/io/timer.v");
        envProperties.setProperty("INTERRUPT_CONTROLLER_V", processorDir + "/io/interrupt_controller.v");
        
        System.out.println("Using auto-detected paths:");
        System.out.println("  HDL_BASE_DIR: " + hdlBaseDir);
        System.out.println("  TEMP_DIR: " + tempDir);
        System.out.println("  PROCESSOR_BASE_DIR: " + processorDir);
    }
    
    /**
     * Find the project root directory by looking for specific markers
     */
    private static File findProjectRoot(File startDir) {
        File current = startDir;
        
        // Look for common project markers
        while (current != null) {
            // Check for Maven project
            if (new File(current, "pom.xml").exists()) {
                return current.getParentFile() != null ? current.getParentFile() : current;
            }
            // Check for AruviXPlatform directory structure
            if (current.getName().equals("AruviXPlatform") || 
                new File(current, "AruviIDE").exists()) {
                return current;
            }
            // Check for processor directory
            if (new File(current, "processor").exists() && 
                new File(current, "AruviIDE").exists()) {
                return current;
            }
            current = current.getParentFile();
        }
        
        // Fallback to current working directory
        return startDir;
    }
    
    /**
     * Find the HDL base directory within the project
     */
    private static String findHdlBaseDir(File projectRoot) {
        // Common HDL directory patterns to check
        String[] hdlDirPatterns = {
            "hdl",
            "processor", 
            "work/hdl",
            "src/hdl",
            "hardware"
        };
        
        for (String pattern : hdlDirPatterns) {
            File hdlDir = new File(projectRoot, pattern);
            if (hdlDir.exists() && hdlDir.isDirectory()) {
                return hdlDir.getAbsolutePath();
            }
        }
        
        // If no HDL directory found, create a default structure
        File defaultHdlDir = new File(projectRoot, "hdl");
        return defaultHdlDir.getAbsolutePath();
    }
    
    /**
     * Get environment variable value
     * @param key The environment variable key
     * @return The value or null if not found
     */
    public static String getEnv(String key) {
        loadEnvFile();
        return envProperties.getProperty(key);
    }
    
    /**
     * Get environment variable value with default fallback
     * @param key The environment variable key
     * @param defaultValue Default value if key not found
     * @return The value or default value
     */
    public static String getEnv(String key, String defaultValue) {
        loadEnvFile();
        return envProperties.getProperty(key, defaultValue);
    }
    
    /**
     * Get all loaded properties (for debugging)
     */
    public static Properties getAllProperties() {
        loadEnvFile();
        return new Properties(envProperties);
    }
    
    /**
     * Print all current environment settings for debugging
     */
    public static void printEnvironmentSettings() {
        loadEnvFile();
        System.out.println("=== AruviIDE Environment Settings ===");
        envProperties.entrySet().stream()
            .sorted((e1, e2) -> e1.getKey().toString().compareTo(e2.getKey().toString()))
            .forEach(entry -> 
                System.out.println(entry.getKey() + " = " + entry.getValue())
            );
        System.out.println("======================================");
    }
    
    /**
     * Force reload of environment file (used by settings dialog)
     */
    public static void reloadEnvironment() {
        envProperties = null;
        loadEnvFile();
    }
    
    /**
     * Clear environment and reload with auto-detection (used by settings dialog)
     */
    public static void clearAndReload() {
        envProperties = null;
        // Delete .env file if it exists to force auto-detection
        File envFile = new File(".env");
        if (envFile.exists()) {
            envFile.delete();
        }
        loadEnvFile();
    }
}
