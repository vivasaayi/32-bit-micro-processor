import javax.swing.*;
import java.awt.*;
import java.awt.image.*;
import java.io.*;
import javax.imageio.ImageIO;

/**
 * Enhanced RISC Processor Framebuffer Viewer
 * Displays PPM images from the processor simulation with improved parsing and rendering
 */
public class SimpleFramebufferViewer extends JFrame {
    private JLabel imageLabel;
    private JLabel statusLabel;
    private JButton refreshButton;
    private JScrollPane scrollPane;
    private String framebufferPath = "../temp/reports/framebuffer.ppm";
    private int frameCount = 0;
    private int zoomFactor = 1;
    private BufferedImage currentImage = null;
    
    public SimpleFramebufferViewer() {
        setTitle("RISC CPU Enhanced Framebuffer Viewer");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLayout(new BorderLayout());
        
        // Image display with scroll pane for zooming
        imageLabel = new JLabel("No image loaded", JLabel.CENTER);
        imageLabel.setPreferredSize(new Dimension(320, 240));
        imageLabel.setBackground(Color.BLACK);
        imageLabel.setOpaque(true);
        imageLabel.setBorder(BorderFactory.createLoweredBevelBorder());
        
        scrollPane = new JScrollPane(imageLabel);
        scrollPane.setPreferredSize(new Dimension(400, 320));
        add(scrollPane, BorderLayout.CENTER);
        
        // Status
        statusLabel = new JLabel("Ready - Enhanced PPM viewer with debugging");
        statusLabel.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
        add(statusLabel, BorderLayout.NORTH);
        
        // Controls
        JPanel controls = new JPanel();
        refreshButton = new JButton("Refresh");
        refreshButton.addActionListener(e -> loadImage());
        controls.add(refreshButton);
        
        JButton autoRefreshButton = new JButton("Auto Refresh");
        autoRefreshButton.addActionListener(e -> startAutoRefresh());
        controls.add(autoRefreshButton);
        
        JButton zoomInButton = new JButton("Zoom In");
        zoomInButton.addActionListener(e -> zoomIn());
        controls.add(zoomInButton);
        
        JButton zoomOutButton = new JButton("Zoom Out");
        zoomOutButton.addActionListener(e -> zoomOut());
        controls.add(zoomOutButton);
        
        JButton debugButton = new JButton("Debug PPM");
        debugButton.addActionListener(e -> debugPPM());
        controls.add(debugButton);
        
        JButton exportBtn = new JButton("Export BMP");
        exportBtn.addActionListener(e -> exportBMP());
        controls.add(exportBtn);
        
        JButton exportButton = new JButton("Export BMP");
        exportButton.addActionListener(e -> exportBMP());
        controls.add(exportButton);
        
        add(controls, BorderLayout.SOUTH);
        
        pack();
        setLocationRelativeTo(null);
        setVisible(true);
        
        // Try to load initial image
        loadImage();
    }
    
    private void loadImage() {
        try {
            File file = new File(framebufferPath);
            if (!file.exists()) {
                statusLabel.setText("File not found: " + framebufferPath);
                return;
            }
            
            BufferedImage img = readPPMRobust(framebufferPath);
            if (img != null) {
                // Store the original image for export
                currentImage = img;
                currentImage = img; // Keep a reference to the current image
                
                // Apply zoom if needed
                if (zoomFactor > 1) {
                    img = scaleImage(img, zoomFactor);
                }
                
                imageLabel.setIcon(new ImageIcon(img));
                frameCount++;
                statusLabel.setText(String.format("Frame %d - %dx%d - Size: %.1f KB - Zoom: %dx", 
                    frameCount, img.getWidth() / zoomFactor, img.getHeight() / zoomFactor, 
                    file.length() / 1024.0, zoomFactor));
                
                // Update the image label size
                imageLabel.setPreferredSize(new Dimension(img.getWidth(), img.getHeight()));
                imageLabel.revalidate();
                scrollPane.revalidate();
            } else {
                statusLabel.setText("Failed to load image");
            }
        } catch (Exception e) {
            statusLabel.setText("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    private void startAutoRefresh() {
        Timer timer = new Timer(50, e -> loadImage()); // Refresh every second
        timer.start();
        statusLabel.setText("Auto refresh started");
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
                throw new IOException("Not enough pixel data. Expected: " + expectedBytes + ", Available: " + availableBytes);
            }
            
            BufferedImage img = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
            byte[] buffer = new byte[(int)expectedBytes];
            raf.readFully(buffer);
            
            int idx = 0;
            int nonBlackPixels = 0;
            for (int y = 0; y < height; y++) {
                for (int x = 0; x < width; x++) {
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
    
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new SimpleFramebufferViewer());
    }
}
