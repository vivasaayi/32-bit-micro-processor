#ifndef STDIO_H
#define STDIO_H

// Printf function declaration
int printf(const char* format, ...);

// Character output function
int putchar(int c);

// String functions
int puts(const char* str);

// Standard file descriptors
#define stdin  0
#define stdout 1  
#define stderr 2

// EOF constant
#define EOF (-1)

#endif /* STDIO_H */
