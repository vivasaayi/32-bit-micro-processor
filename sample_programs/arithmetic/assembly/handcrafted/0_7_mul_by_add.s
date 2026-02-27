# Multiply two numbers (e.g., 7 * 6) using repeated addition
# Result stored in R3

.org 0x8000

main:
# Initialize registers
LOADI R1, #7 # R1 = 7 (multiplicand)
LOADI R31, #6 # R31 = 6 (multiplier/loop counter)
LOADI R3, #0 # R3 = 0 (result accumulator)

mul_loop:
CMP R31, R0 # Check if counter is zero
JZ end_mul
ADD R3, R3, R1 # R3 += R1
SUBI R31, R31, #1 # R31--
JMP mul_loop

end_mul:
STORE R3, 0x7000 # Store result (should be 42)
HALT
