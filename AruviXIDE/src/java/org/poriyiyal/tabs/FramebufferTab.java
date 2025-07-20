package org.poriyiyal.tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.image.*;
import java.io.*;
import javax.imageio.ImageIO;
import java.util.Timer;
import java.util.TimerTask;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

import org.poriyiyal.util.AppState;
import org.poriyiyal.CpuIDE;

/**
 * Framebuffer Graphics Tab for CPU IDE
 * Integrates PPM framebuffer viewing into the main IDE
 */
public class FramebufferTab extends BaseTab {
    private JLabel imageLabel;
    private JLabel statusLabel;
    private JScrollPane scrollPane;
    private String framebufferPath = "../temp/reports/framebuffer.ppm";
    private String framebufferDir = "../temp/reports";
    private int frameCount = 0;
    private int zoomFactor = 1;
    private BufferedImage currentImage = null;
    private Timer autoRefreshTimer = null;
    private boolean autoRefreshEnabled = false;
    private JPanel imagePanel; // Panel to center imageLabel
    private boolean fitToWindow = false;
    private int refreshIntervalMs = 100; // Default 100ms for smooth animation
    private long lastFileModified = 0; // Track file changes for smart refresh
    
    // Multi-frame support
    private java.util.List<String> frameFiles = new ArrayList<>();
    private int currentFrameIndex = -1;
    private boolean multiFrameMode = false;
    
    public FramebufferTab(AppState appState, CpuIDE parentFrame) {
        super(appState, parentFrame);
        loadImage(); // Try to load initial image
    }
    
    @Override
    protected void initializeComponents() {
        // Image display with scroll pane for zooming
        imageLabel = new JLabel("No framebuffer loaded", JLabel.CENTER);
        imageLabel.setPreferredSize(new Dimension(320, 240));
        imageLabel.setBackground(Color.BLACK);
        imageLabel.setOpaque(true);
        imageLabel.setBorder(BorderFactory.createLoweredBevelBorder());

        // Center imageLabel in a panel
        imagePanel = new JPanel(new GridBagLayout());
        imagePanel.setBackground(Color.BLACK);
        imagePanel.add(imageLabel, new GridBagConstraints());

        scrollPane = new JScrollPane(imagePanel);
        scrollPane.setPreferredSize(new Dimension(400, 320));

        // Status label
        statusLabel = new JLabel("Ready - Framebuffer Viewer");
        statusLabel.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
    }
    
    @Override
    protected void setupLayout() {
        setLayout(new BorderLayout());
        
        // Status at top
        add(statusLabel, BorderLayout.NORTH);
        
        // Image display in center
        add(scrollPane, BorderLayout.CENTER);
        
        // Controls at bottom
        JPanel controls = new JPanel(new GridLayout(2, 1, 0, 2));
        JPanel buttonRow1 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 6));
        JPanel buttonRow2 = new JPanel(new FlowLayout(FlowLayout.LEFT, 6, 6));
        
        // First row: refresh, live, rate, speed, zoom, fit
        JButton refreshButton = new JButton("🔄 Refresh");
        refreshButton.addActionListener(e -> loadImage());
        buttonRow1.add(refreshButton);

        JButton autoRefreshButton = new JButton("⚡ Live Monitor");
        autoRefreshButton.addActionListener(e -> toggleAutoRefresh());
        buttonRow1.add(autoRefreshButton);

        JLabel rateLabel = new JLabel("Rate:");
        buttonRow1.add(rateLabel);

        JButton ultraFastButton = new JButton("⚡ Ultra (16ms)");
        ultraFastButton.addActionListener(e -> setRefreshRate(16));
        buttonRow1.add(ultraFastButton);

        JButton fastButton = new JButton("🏃 Fast (33ms)");
        fastButton.addActionListener(e -> setRefreshRate(33));
        buttonRow1.add(fastButton);

        JButton normalButton = new JButton("🚶 Normal (100ms)");
        normalButton.addActionListener(e -> setRefreshRate(100));
        buttonRow1.add(normalButton);

        JButton slowButton = new JButton("🐌 Slow (500ms)");
        slowButton.addActionListener(e -> setRefreshRate(500));
        buttonRow1.add(slowButton);

        JButton zoomInButton = new JButton("🔍+ Zoom In");
        zoomInButton.addActionListener(e -> zoomIn());
        buttonRow1.add(zoomInButton);

        JButton zoomOutButton = new JButton("🔍- Zoom Out");
        zoomOutButton.addActionListener(e -> zoomOut());
        buttonRow1.add(zoomOutButton);

        JButton fitButton = new JButton("🖼️ Fit to Window");
        fitButton.addActionListener(e -> { fitToWindow = !fitToWindow; loadImage(); });
        buttonRow1.add(fitButton);


        // Second row: frame navigation, debug, export, and movie controls
        JButton scanFramesButton = new JButton("🔍 Scan Frames");
        scanFramesButton.addActionListener(e -> scanForFrames());
        buttonRow2.add(scanFramesButton);

        JButton prevFrameButton = new JButton("◀ Prev");
        prevFrameButton.addActionListener(e -> previousFrame());
        buttonRow2.add(prevFrameButton);

        JButton nextFrameButton = new JButton("▶ Next");
        nextFrameButton.addActionListener(e -> nextFrame());
        buttonRow2.add(nextFrameButton);

        JButton latestFrameButton = new JButton("⏩ Latest");
        latestFrameButton.addActionListener(e -> showLatestFrame());
        buttonRow2.add(latestFrameButton);

        // Play/Pause button for movie mode
        JButton playPauseButton = new JButton("▶ Play");
        buttonRow2.add(playPauseButton);
        playPauseButton.addActionListener(e -> toggleMovieMode(playPauseButton));

        JButton debugButton = new JButton("🔧 Debug PPM");
        debugButton.addActionListener(e -> debugPPM());
        buttonRow2.add(debugButton);

        JButton exportButton = new JButton("💾 Export BMP");
        exportButton.addActionListener(e -> exportBMP());
        buttonRow2.add(exportButton);

        controls.add(buttonRow1);
        controls.add(buttonRow2);
        add(controls, BorderLayout.SOUTH);
    }

    // ===== Movie mode state and methods (moved to class level) =====
    private Timer movieTimer = null;
    private boolean moviePlaying = false;

    // Toggle movie mode (play/pause)
    private void toggleMovieMode(JButton playPauseButton) {
        if (!multiFrameMode || frameFiles.isEmpty()) {
            statusLabel.setText("No frames loaded. Click 'Scan Frames' first.");
            return;
        }
        if (moviePlaying) {
            stopMovieMode(playPauseButton);
        } else {
            startMovieMode(playPauseButton);
        }
    }

    private void startMovieMode(JButton playPauseButton) {
        if (movieTimer != null) movieTimer.cancel();
        moviePlaying = true;
        playPauseButton.setText("⏸ Pause");
        // Always rescan frames before playing
        scanForFrames();
        if (currentFrameIndex < 0) currentFrameIndex = 0;
        movieTimer = new Timer();
        movieTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                SwingUtilities.invokeLater(() -> {
                    // Rescan for new frames during playback
                    int prevFrameCount = frameFiles.size();
                    scanForFramesSilently();
                    int newFrameCount = frameFiles.size();
                    if (!multiFrameMode || frameFiles.isEmpty()) {
                        stopMovieMode(playPauseButton);
                        return;
                    }
                    if (currentFrameIndex < frameFiles.size() - 1) {
                        currentFrameIndex++;
                        loadFrameAt(currentFrameIndex);
                    } else {
                        // Stay at last frame, but if new frames appear, advance
                        if (newFrameCount > prevFrameCount) {
                            currentFrameIndex = newFrameCount - 1;
                            loadFrameAt(currentFrameIndex);
                        }
                        // Otherwise, do nothing (keep polling)
                    }
                });
            }
        }, 0, refreshIntervalMs);
        statusLabel.setText("Movie mode: Playing");
    }

    private void stopMovieMode(JButton playPauseButton) {
        if (movieTimer != null) {
            movieTimer.cancel();
            movieTimer = null;
        }
        moviePlaying = false;
        playPauseButton.setText("▶ Play");
        statusLabel.setText("Movie mode: Paused");
    }

    // Rescan frames without resetting navigation or status
    private void scanForFramesSilently() {
        File directory = new File(framebufferDir);
        if (!directory.exists() || !directory.isDirectory()) {
            return;
        }
        File[] files = directory.listFiles((dir, name) ->
            name.startsWith("frame_") && name.endsWith(".ppm"));
        if (files == null || files.length == 0) {
            return;
        }
        Arrays.sort(files, (f1, f2) -> f1.getName().compareTo(f2.getName()));
        List<String> newFrameFiles = new ArrayList<>();
        for (File file : files) {
            newFrameFiles.add(file.getAbsolutePath());
        }
        // Only update if new frames are found
        if (newFrameFiles.size() != frameFiles.size() ||
            !newFrameFiles.equals(frameFiles)) {
            frameFiles = newFrameFiles;
        }
        multiFrameMode = true;
    }
    
    @Override
    public void loadContent(String content) {
        // For framebuffer tab, content could be a path to a different PPM file
        if (content != null && !content.trim().isEmpty()) {
            framebufferPath = content;
        }
        loadImage();
    }
    
    @Override
    public void saveContent() {
        // Export current framebuffer to BMP
        exportBMP();
    }
    
    @Override
    public void clearContent() {
        imageLabel.setIcon(null);
        imageLabel.setText("No framebuffer loaded");
        currentImage = null;
        frameCount = 0;
        statusLabel.setText("Content cleared");
    }
    
    private void loadImage() {
        // In multi-frame mode, auto-refresh scans for new frames and shows the latest
        if (multiFrameMode && autoRefreshEnabled) {
            scanForFrames(); // This will automatically show the latest frame
            return;
        }
        
        // Standard single-file mode
        try {
            File file = new File(framebufferPath);
            if (!file.exists()) {
                if (!autoRefreshEnabled) {
                    statusLabel.setText("File not found: " + framebufferPath);
                    imageLabel.setIcon(null);
                    imageLabel.setText("No framebuffer file found");
                }
                return;
            }

            // Smart refresh: only reload if file has been modified
            long currentModified = file.lastModified();
            if (autoRefreshEnabled && currentModified == lastFileModified && currentImage != null) {
                return; // No change, skip reload for performance
            }
            lastFileModified = currentModified;

            BufferedImage img = readPPMRobust(framebufferPath);
            if (img != null) {
                currentImage = img;
                displayCurrentImage();
                frameCount++;
                String refreshInfo = autoRefreshEnabled ? String.format(" | Live@%dms", refreshIntervalMs) : "";
                statusLabel.setText(String.format("Frame %d - %dx%d - Size: %.1f KB - Zoom: %s%s", 
                    frameCount, currentImage.getWidth(), currentImage.getHeight(), 
                    file.length() / 1024.0, fitToWindow ? "Fit" : zoomFactor, refreshInfo));
            } else {
                // During live monitoring, don't show errors for incomplete files
                if (!autoRefreshEnabled) {
                    statusLabel.setText("Failed to load framebuffer image");
                    imageLabel.setIcon(null);
                    imageLabel.setText("Failed to load image");
                }
            }
        } catch (Exception e) {
            // During live monitoring, don't show errors for temporary I/O issues
            if (!autoRefreshEnabled) {
                statusLabel.setText("Error: " + e.getMessage());
                imageLabel.setIcon(null);
                imageLabel.setText("Error loading image");
                e.printStackTrace();
            }
        }
    }
    
    private void toggleAutoRefresh() {
        if (autoRefreshEnabled) {
            // Stop auto refresh
            if (autoRefreshTimer != null) {
                autoRefreshTimer.cancel();
                autoRefreshTimer = null;
            }
            autoRefreshEnabled = false;
            statusLabel.setText("Live monitor stopped");
        } else {
            // Start auto refresh
            startLiveMonitor();
        }
    }
    
    private void startLiveMonitor() {
        if (autoRefreshTimer != null) {
            autoRefreshTimer.cancel();
        }
        autoRefreshTimer = new Timer();
        autoRefreshTimer.scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                SwingUtilities.invokeLater(() -> loadImage());
            }
        }, 0, refreshIntervalMs);
        autoRefreshEnabled = true;
        statusLabel.setText(String.format("Live monitor started (%dms refresh rate)", refreshIntervalMs));
    }
    
    private void setRefreshRate(int intervalMs) {
        refreshIntervalMs = intervalMs;
        if (autoRefreshEnabled) {
            // Restart with new rate
            startLiveMonitor();
        } else {
            statusLabel.setText(String.format("Refresh rate set to %dms (not active)", refreshIntervalMs));
        }
    }
    
    private void zoomIn() {
        if (zoomFactor < 8) {
            zoomFactor++;
            loadImage();
        }
    }
    
    private void zoomOut() {
        if (zoomFactor > 1) {
            zoomFactor--;
            loadImage();
        }
    }
    
    private void debugPPM() {
        try {
            debugPPMFile(framebufferPath);
        } catch (Exception e) {
            statusLabel.setText("Debug error: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void exportBMP() {
        if (currentImage == null) {
            statusLabel.setText("No image to export - load an image first");
            return;
        }
        
        try {
            String outputFile = "../temp/reports/framebuffer_export.bmp";
            File outputFileObj = new File(outputFile);
            ImageIO.write(currentImage, "BMP", outputFileObj);
            statusLabel.setText("Exported to: " + outputFile);
            System.out.println("Image exported to: " + outputFile);
        } catch (Exception e) {
            statusLabel.setText("Export failed: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    // Frame navigation methods
    private void scanForFrames() {
        frameFiles.clear();
        currentFrameIndex = -1;
        multiFrameMode = false;
        
        File directory = new File(framebufferDir);
        if (!directory.exists() || !directory.isDirectory()) {
            statusLabel.setText("Directory not found: " + framebufferDir);
            return;
        }
        
        // Look for frame_*.ppm files
        File[] files = directory.listFiles((dir, name) -> 
            name.startsWith("frame_") && name.endsWith(".ppm"));
        
        if (files == null || files.length == 0) {
            statusLabel.setText("No frame files found in " + framebufferDir);
            return;
        }
        
        // Sort files by name to get them in order
        Arrays.sort(files, (f1, f2) -> f1.getName().compareTo(f2.getName()));
        
        for (File file : files) {
            frameFiles.add(file.getAbsolutePath());
        }
        
        multiFrameMode = true;
        statusLabel.setText("Found " + frameFiles.size() + " frame files. Use navigation buttons to browse.");
        
        // If in auto-refresh mode, show the latest frame automatically
        if (autoRefreshEnabled) {
            showLatestFrame();
        }
    }
    
    private void previousFrame() {
        if (!multiFrameMode || frameFiles.isEmpty()) {
            statusLabel.setText("No frames loaded. Click 'Scan Frames' first.");
            return;
        }
        
        if (currentFrameIndex > 0) {
            currentFrameIndex--;
            loadFrameAt(currentFrameIndex);
        } else {
            statusLabel.setText("Already at first frame");
        }
    }
    
    private void nextFrame() {
        if (!multiFrameMode || frameFiles.isEmpty()) {
            statusLabel.setText("No frames loaded. Click 'Scan Frames' first.");
            return;
        }
        
        if (currentFrameIndex < frameFiles.size() - 1) {
            currentFrameIndex++;
            loadFrameAt(currentFrameIndex);
        } else {
            statusLabel.setText("Already at last frame");
        }
    }
    
    private void showLatestFrame() {
        if (!multiFrameMode || frameFiles.isEmpty()) {
            statusLabel.setText("No frames loaded. Click 'Scan Frames' first.");
            return;
        }
        
        currentFrameIndex = frameFiles.size() - 1;
        loadFrameAt(currentFrameIndex);
    }
    
    private void loadFrameAt(int index) {
        if (index < 0 || index >= frameFiles.size()) {
            statusLabel.setText("Invalid frame index: " + index);
            return;
        }
        
        String framePath = frameFiles.get(index);
        try {
            BufferedImage img = readPPMRobust(framePath);
            if (img != null) {
                currentImage = img;
                displayCurrentImage();
                String fileName = new File(framePath).getName();
                statusLabel.setText(String.format("Frame %d/%d: %s - %dx%d", 
                    index + 1, frameFiles.size(), fileName, 
                    img.getWidth(), img.getHeight()));
            } else {
                statusLabel.setText("Failed to load frame: " + framePath);
            }
        } catch (Exception e) {
            statusLabel.setText("Error loading frame: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void displayCurrentImage() {
        if (currentImage == null) {
            imageLabel.setIcon(null);
            imageLabel.setText("No image loaded");
            return;
        }
        
        BufferedImage displayImg = currentImage;
        if (fitToWindow) {
            // Scale to fit scrollPane viewport
            Dimension vp = scrollPane.getViewport().getExtentSize();
            int w = vp.width, h = vp.height;
            double scale = Math.min((double)w/currentImage.getWidth(), 
                                  (double)h/currentImage.getHeight());
            if (scale < 1.0) {
                int sw = (int)(currentImage.getWidth()*scale);
                int sh = (int)(currentImage.getHeight()*scale);
                displayImg = scaleImage(currentImage, sw, sh);
            }
        } else if (zoomFactor > 1) {
            displayImg = scaleImage(currentImage, zoomFactor);
        }
        
        imageLabel.setIcon(new ImageIcon(displayImg));
        imageLabel.setText("");
        imageLabel.setPreferredSize(new Dimension(displayImg.getWidth(), displayImg.getHeight()));
        imageLabel.revalidate();
        imagePanel.revalidate();
        scrollPane.revalidate();
    }
    
    private BufferedImage scaleImage(BufferedImage original, int scale) {
        int w = original.getWidth() * scale;
        int h = original.getHeight() * scale;
        BufferedImage scaled = new BufferedImage(w, h, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = scaled.createGraphics();
        g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR);
        g2d.drawImage(original, 0, 0, w, h, null);
        g2d.dispose();
        return scaled;
    }
    
    private BufferedImage scaleImage(BufferedImage original, int width, int height) {
        Image tmp = original.getScaledInstance(width, height, Image.SCALE_SMOOTH);
        BufferedImage scaled = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = scaled.createGraphics();
        g2d.drawImage(tmp, 0, 0, null);
        g2d.dispose();
        return scaled;
    }
    
    private BufferedImage readPPMRobust(String path) throws IOException {
        File file = new File(path);
        System.out.println("Reading PPM file: " + path + " (size: " + file.length() + " bytes)");
        
        try (RandomAccessFile raf = new RandomAccessFile(file, "r")) {
            // Read header as text
            String magic = readTextLine(raf);
            System.out.println("Magic: '" + magic + "'");
            
            if (!magic.equals("P6")) {
                throw new IOException("Only P6 PPM format supported, got: " + magic);
            }
            
            // Skip comments and read dimensions
            String line;
            do {
                line = readTextLine(raf);
                System.out.println("Header line: '" + line + "'");
            } while (line.startsWith("#"));
            
            String[] dims = line.trim().split("\\s+");
            if (dims.length < 2) {
                throw new IOException("Invalid dimensions line: " + line);
            }
            
            int width = Integer.parseInt(dims[0]);
            int height = Integer.parseInt(dims[1]);
            System.out.println("Dimensions: " + width + "x" + height);
            
            String maxvalLine = readTextLine(raf);
            int maxval = Integer.parseInt(maxvalLine.trim());
            System.out.println("Max value: " + maxval);
            
            // Now read binary pixel data
            long dataStart = raf.getFilePointer();
            long expectedBytes = width * height * 3L;
            long availableBytes = file.length() - dataStart;
            
            System.out.println("Data starts at offset: " + dataStart);
            System.out.println("Expected pixel data: " + expectedBytes + " bytes");
            System.out.println("Available pixel data: " + availableBytes + " bytes");
            
            if (availableBytes < expectedBytes) {
                // Not enough data - could be during live writing, return null to retry later
                System.out.println("Warning: Not enough pixel data. Expected: " + expectedBytes + ", Available: " + availableBytes);
                if (autoRefreshEnabled) {
                    return null; // Silently fail during live monitoring, will retry
                } else {
                    throw new IOException("Not enough pixel data. Expected: " + expectedBytes + ", Available: " + availableBytes);
                }
            }
            
            BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            byte[] buffer = new byte[(int)expectedBytes];
            raf.readFully(buffer);
            
            int idx = 0;
            int nonBlackPixels = 0;
            int pixelsToRead = (int)(expectedBytes / 3); // How many complete pixels we can read
            int pixelCount = 0;
            
            for (int y = 0; y < height && pixelCount < pixelsToRead; y++) {
                for (int x = 0; x < width && pixelCount < pixelsToRead; x++) {
                    if (idx + 2 < buffer.length) {
                        int r = (buffer[idx++] & 0xFF);
                        int g = (buffer[idx++] & 0xFF);
                        int b = (buffer[idx++] & 0xFF);
                    
                        // Scale values if needed
                        if (maxval != 255) {
                            r = r * 255 / maxval;
                            g = g * 255 / maxval;
                            b = b * 255 / maxval;
                        }
                        
                        int rgb = (r << 16) | (g << 8) | b;
                        img.setRGB(x, y, rgb);
                        
                        if (rgb != 0) nonBlackPixels++;
                        pixelCount++;
                    } else {
                        // Not enough data for this pixel, fill with black
                        img.setRGB(x, y, 0);
                    }
                }
            }
            
            System.out.println("Successfully loaded image with " + nonBlackPixels + " non-black pixels");
            return img;
        }
    }
    
    private String readTextLine(RandomAccessFile raf) throws IOException {
        StringBuilder sb = new StringBuilder();
        int b;
        while ((b = raf.read()) != -1 && b != '\n') {
            if (b != '\r') {  // Skip carriage return
                sb.append((char) b);
            }
        }
        return sb.toString();
    }
    
    private void debugPPMFile(String path) {
        try {
            File file = new File(path);
            System.out.println("\n=== PPM DEBUG INFO ===");
            System.out.println("File: " + path);
            System.out.println("Exists: " + file.exists());
            System.out.println("Size: " + file.length() + " bytes");
            System.out.println("Readable: " + file.canRead());
            
            if (file.exists() && file.canRead()) {
                // Read first 200 bytes as both text and hex
                try (RandomAccessFile raf = new RandomAccessFile(file, "r")) {
                    int readLen = Math.min(200, (int)file.length());
                    byte[] header = new byte[readLen];
                    raf.readFully(header);
                    
                    System.out.println("\nFirst " + readLen + " bytes as text:");
                    StringBuilder text = new StringBuilder();
                    for (int i = 0; i < readLen; i++) {
                        byte b = header[i];
                        if (b >= 32 && b <= 126) {
                            text.append((char)b);
                        } else if (b == '\n') {
                            text.append("\\n");
                        } else if (b == '\r') {
                            text.append("\\r");
                        } else {
                            text.append("[" + (b & 0xFF) + "]");
                        }
                    }
                    System.out.println("'" + text.toString() + "'");
                    
                    System.out.println("\nFirst " + Math.min(50, readLen) + " bytes as hex:");
                    for (int i = 0; i < Math.min(50, readLen); i++) {
                        System.out.printf("%02X ", header[i] & 0xFF);
                        if ((i + 1) % 16 == 0) System.out.println();
                    }
                    System.out.println();
                }
                
                // Try to parse header manually
                System.out.println("\nAttempting to parse header...");
                try (RandomAccessFile raf = new RandomAccessFile(file, "r")) {
                    String magic = readTextLine(raf);
                    System.out.println("Magic: '" + magic + "'");
                    
                    String line;
                    int lineCount = 0;
                    do {
                        line = readTextLine(raf);
                        System.out.println("Line " + (++lineCount) + ": '" + line + "'");
                    } while (line.startsWith("#") && lineCount < 10);
                    
                    String maxvalLine = readTextLine(raf);
                    System.out.println("Maxval line: '" + maxvalLine + "'");
                    
                    long dataStart = raf.getFilePointer();
                    System.out.println("Data should start at offset: " + dataStart);
                    System.out.println("Remaining bytes for pixel data: " + (file.length() - dataStart));
                }
            }
            System.out.println("=== END DEBUG ===\n");
            
            // Also update the status
            statusLabel.setText("Debug info printed to console - check terminal");
            
        } catch (Exception e) {
            System.out.println("Debug error: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Cleanup resources when tab is closed or disposed
     */
    public void cleanup() {
        if (autoRefreshTimer != null) {
            autoRefreshTimer.cancel();
            autoRefreshTimer = null;
        }
        if (movieTimer != null) {
            movieTimer.cancel();
            movieTimer = null;
        }
        autoRefreshEnabled = false;
        moviePlaying = false;
    }
}
