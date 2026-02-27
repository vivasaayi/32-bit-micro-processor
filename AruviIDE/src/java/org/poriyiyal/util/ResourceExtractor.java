/*
 * Copyright (c) 2026 Rajan Panneerselvam
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package org.poriyiyal.util;

import java.io.*;
import java.nio.file.*;
import java.util.jar.JarFile;
import java.util.zip.ZipEntry;

/**
 * Utility to extract embedded resources from JAR to temporary directory
 */
public class ResourceExtractor {
    private static File tempDir;

    static {
        try {
            tempDir = Files.createTempDirectory("AruviXPlatform").toFile();
            tempDir.deleteOnExit();
            extractResources();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static void extractResources() throws IOException {
        // Get the JAR file containing this class
        String jarPath = ResourceExtractor.class.getProtectionDomain()
                .getCodeSource().getLocation().getPath();
        File jarFile = new File(jarPath);

        if (jarFile.isFile()) {
            try (JarFile jar = new JarFile(jarFile)) {
                jar.stream().forEach(entry -> extractEntry(jar, entry));
            }
        }
    }

    private static void extractEntry(JarFile jar, ZipEntry entry) {
        String name = entry.getName();
        if (name.startsWith("bin/") || name.startsWith("hdl/") || name.startsWith("test_programs/")) {
            try {
                File outputFile = new File(tempDir, name);
                if (entry.isDirectory()) {
                    outputFile.mkdirs();
                } else {
                    outputFile.getParentFile().mkdirs();
                    try (InputStream is = jar.getInputStream(entry);
                         FileOutputStream fos = new FileOutputStream(outputFile)) {
                        byte[] buffer = new byte[1024];
                        int bytesRead;
                        while ((bytesRead = is.read(buffer)) != -1) {
                            fos.write(buffer, 0, bytesRead);
                        }
                    }
                    // Make binaries executable
                    if (name.startsWith("bin/")) {
                        outputFile.setExecutable(true);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public static File getTempDir() {
        return tempDir;
    }

    public static String getTestProgramsPath() {
        return new File(tempDir, "test_programs").getAbsolutePath();
    }

    public static String getBinPath() {
        return new File(tempDir, "bin").getAbsolutePath();
    }

    public static String getHdlPath() {
        return new File(tempDir, "hdl").getAbsolutePath();
    }
}