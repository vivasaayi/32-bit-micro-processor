package tabs;

import javax.swing.*;
import java.awt.*;
import java.awt.image.*;
import java.io.*;
import javax.imageio.ImageIO;
import java.util.Timer;
import java.util.TimerTask;
import util.AppState;
import main.CpuIDE;

/**
 * Framebuffer Graphics Tab for CPU IDE
 * Integrates PPM framebuffer viewing into the main IDE
 */
public class FramebufferTab extends BaseTab {
    private JLabel imageLabel;
    private JLabel statusLabel;
    private JScrollPane scrollPane;
    private String framebufferPath = "/Users/rajanpanneerselvam/work/hdl/temp/reports/framebuffer.ppm";
    private int frameCount = 0;
    private int zoomFactor = 1;
    private BufferedImage currentImage = null;
    private Timer autoRefreshTimer = null;
    private boolean autoRefreshEnabled = false;
    private JPanel imagePanel; // Panel to center imageLabel
    private boolean fitToWindow = false;
    private int refreshIntervalMs = 100; // Default 100ms for smooth animation
    private long lastFileModified = 0; // Track file changes for smart refresh
    
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
        JPanel controls = new JPanel(new FlowLayout());
        
        JButton refreshButton = new JButton("🔄 Refresh");
        refreshButton.addActionListener(e -> loadImage());
        controls.add(refreshButton);
        
        JButton autoRefreshButton = new JButton("⚡ Live Monitor");
        autoRefreshButton.addActionListener(e -> toggleAutoRefresh());
        controls.add(autoRefreshButton);
        
        // Refresh rate controls for animation
        JLabel rateLabel = new JLabel("Rate:");
        controls.add(rateLabel);
        
        JButton ultraFastButton = new JButton("⚡ Ultra (16ms)");
        ultraFastButton.addActionListener(e -> setRefreshRate(16)); // ~60 FPS
        controls.add(ultraFastButton);
        
        JButton fastButton = new JButton("🏃 Fast (33ms)");
        fastButton.addActionListener(e -> setRefreshRate(33)); // ~30 FPS
        controls.add(fastButton);
        
        JButton normalButton = new JButton("🚶 Normal (100ms)");
        normalButton.addActionListener(e -> setRefreshRate(100)); // 10 FPS
        controls.add(normalButton);
        
        JButton slowButton = new JButton("🐌 Slow (500ms)");
        slowButton.addActionListener(e -> setRefreshRate(500)); // 2 FPS
        controls.add(slowButton);
        
        JButton zoomInButton = new JButton("🔍+ Zoom In");
        zoomInButton.addActionListener(e -> zoomIn());
        controls.add(zoomInButton);
        
        JButton zoomOutButton = new JButton("🔍- Zoom Out");
        zoomOutButton.addActionListener(e -> zoomOut());
        controls.add(zoomOutButton);
        
        JButton fitButton = new JButton("� Fit to Window");
        fitButton.addActionListener(e -> { fitToWindow = !fitToWindow; loadImage(); });
        controls.add(fitButton);
        
        JButton debugButton = new JButton("� Debug PPM");
        debugButton.addActionListener(e -> debugPPM());
        controls.add(debugButton);
        
        JButton exportButton = new JButton("💾 Export BMP");
        exportButton.addActionListener(e -> exportBMP());
        controls.add(exportButton);
        
        add(controls, BorderLayout.SOUTH);
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
                BufferedImage displayImg = img;
                if (fitToWindow) {
                    // Scale to fit scrollPane viewport
                    Dimension vp = scrollPane.getViewport().getExtentSize();
                    int w = vp.width, h = vp.height;
                    double scale = Math.min((double)w/img.getWidth(), (double)h/img.getHeight());
                    if (scale < 1.0) {
                        int sw = (int)(img.getWidth()*scale);
                        int sh = (int)(img.getHeight()*scale);
                        displayImg = scaleImage(img, sw, sh);
                    }
                } else if (zoomFactor > 1) {
                    displayImg = scaleImage(img, zoomFactor);
                }
                imageLabel.setIcon(new ImageIcon(displayImg));
                imageLabel.setText("");
                frameCount++;
                String refreshInfo = autoRefreshEnabled ? String.format(" | Live@%dms", refreshIntervalMs) : "";
                statusLabel.setText(String.format("Frame %d - %dx%d - Size: %.1f KB - Zoom: %sx%s", 
                    frameCount, currentImage.getWidth(), currentImage.getHeight(), 
                    file.length() / 1024.0, fitToWindow ? "Fit" : zoomFactor, refreshInfo));
                imageLabel.setPreferredSize(new Dimension(displayImg.getWidth(), displayImg.getHeight()));
                imageLabel.revalidate();
                imagePanel.revalidate();
                scrollPane.revalidate();
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
        autoRefreshEnabled = false;
    }
}
