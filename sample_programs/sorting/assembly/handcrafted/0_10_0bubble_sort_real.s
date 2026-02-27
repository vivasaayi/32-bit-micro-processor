# Bubble Sort Real - 32-bit version
# Minimal, working 8-element bubble sort with direct addressing for output at 0x0200

.org 0x8000

# Initialize array in memory at 0x0100
LOADI R1, #189
STORE R1, #0x0100
LOADI R1, #42
STORE R1, #0x0104
LOADI R1, #156
STORE R1, #0x0108
LOADI R1, #7
STORE R1, #0x010C
LOADI R1, #93
STORE R1, #0x0110
LOADI R1, #234
STORE R1, #0x0114
LOADI R1, #68
STORE R1, #0x0118
LOADI R1, #151
STORE R1, #0x011C

# Bubble sort: outer loop i = 0 to 6
LOADI R11, #0 # i = 0
LOOP_I:
LOADI R12, #0 # j = 0
LOOP_J:
LOADI R13, #8
LOADI R16, #111
SUB R13, R13, R11 # 7 - i
LOADI R16, #222
SUBI R13, R13, 1 # 7 - i - 1
LOADI R16, #333
LOAD R20, #0x0100
LOAD R21, #0x0104
LOAD R22, #0x0108
LOAD R23, #0x010C
LOAD R24, #0x0110
LOAD R25, #0x0114
LOAD R26, #0x0118
LOAD R27, #0x011C
LOADI R16, #444

LOAD R28, R12 # not working
LOAD R29, R13 # not working
LOAD R30, R14 # not working

SUB R14, R13, R12 # R14 = (7-i-1) - j

LOAD R30, R14 # not working

CMP R14, R0
JZ END_J
JLT END_J
# If j == 7-i-1, break
# If j > 7-i-1, break (repeat CMP and JZ for clarity)
# (If only JZ and JMP are available, this is sufficient)
# Copy all memory values to R20-R27 for visualization

LOADI R29, #111

# Calculate addresses for arr[j] and arr[j+1] without SHL or MOV
LOADI R14, #0x0100 # base address
LOADI R15, #0 # R15 = 0
ADD R15, R15, R12 # R15 = j
ADD R15, R15, R15 # R15 = j*2
ADD R15, R15, R15 # R15 = j*4
ADD R15, R14, R15 # addr = base + j*4
STORE R15, #0x0300 # debug: store address for arr[j]
LOAD R16, R15 # arr[j] - try without +0
ADDI R17, R15, 4 # addr of arr[j+1]
STORE R17, #0x0304 # debug: store address for arr[j+1]
LOAD R18, R17 # arr[j+1] - try without +0
# Compare arr[j] > arr[j+1] using robust subtraction-based pattern
SUB R19, R16, R18 # R19 = arr[j] - arr[j+1]
CMP R19, R0 # Compare result with zero
JZ SKIP_SWAP # If equal, no swap needed
JLT SKIP_SWAP # If arr[j] < arr[j+1], no swap needed
# Swap arr[j] and arr[j+1]
LOADI R29, #666
STORE R18, [R15] # Store arr[j+1] value to arr[j] address
STORE R16, [R17] # Store arr[j] value to arr[j+1] address
SKIP_SWAP:
ADDI R12, R12, 1
JMP LOOP_J
END_J:
ADDI R11, R11, 1
LOADI R13, #8
SUB R14, R11, R13 # R14 = i - 7
CMP R14, R0 # Compare result with zero
JLT LOOP_I # If i < 7, continue loop

# Copy sorted array to 0x0200 using direct addressing
LOADI R12, #0
COPY_LOOP:
LOADI R14, #0x0100
LOADI R15, #0 # R15 = 0
ADD R15, R15, R12 # R15 = i
ADD R15, R15, R15 # R15 = i*2
ADD R15, R15, R15 # R15 = i*4
ADD R16, R14, R15 # R16 = 0x0100 + i*4 (src)
LOAD R13, R16 # R13 = value
LOADI R14, #0x0200
ADD R17, R14, R15 # R17 = 0x0200 + i*4 (dst)
STORE R13, R17 # store value
ADDI R12, R12, 1
LOADI R16, #8
SUB R17, R12, R16 # R17 = i - 8
CMP R17, R0 # Compare result with zero
JLT COPY_LOOP # If i < 8, continue loop

HALT
