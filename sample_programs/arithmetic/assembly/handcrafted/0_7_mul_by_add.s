# Multiply two numbers (e.g., 7 * 6) using repeated addition
# Result stored in R3

.org 0x8000

main:
# Initialize registers
addi R1, zero, 7 # R1 = 7 (multiplicand)
addi R31, zero, 6 # R31 = 6 (multiplier/loop counter)
addi R3, zero, 0 # R3 = 0 (result accumulator)

mul_loop:
CMP R31, R0 # Check if counter is zero
JZ end_mul
ADD R3, R3, R1 # R3 += R1
addi R31, R31, -1 # R31--
JMP mul_loop

end_mul:
sw R3, 0(0x7000) # Store result (should be 42)
HALT
