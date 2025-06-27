/*
 * String Logging System for C Programs
 * 
 * Memory Layout:
 * 0x3000-0x3FFF: String log buffer (4KB for messages)
 * 0x4000: String length counter
 * 0x4004: Log status/control register
 */

#ifndef STRING_LOGGER_H
#define STRING_LOGGER_H

// Memory addresses for logging system
#define LOG_BUFFER_BASE   0x3000    // 4KB buffer for log strings
#define LOG_LENGTH_ADDR   0x4000    // Current length of log string
#define LOG_STATUS_ADDR   0x4004    // Status/control register
#define LOG_BUFFER_SIZE   4096      // Maximum log buffer size

// Logging functions (to be implemented in C compiler)
void log_init();
void log_append(const char* message);
void log_finalize();

// Helper macros
#define LOG(msg) log_append(msg)

#endif // STRING_LOGGER_H
