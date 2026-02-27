.org 0x8000

_start:
# Setup UART address (0x10000000)
# Using LUI + ADDI (manual since UART is high)
lui    s1, 0x10000

# Test 1: "Hello" (Length 5)
la     a0, test_str1
call   strlen
# a0 = 5. Convert to '5' (0x35)
addi   t0, a0, 48
sb     t0, 0(s1)
li     t1, 10      # Newline
sb     t1, 0(s1)

# Test 2: "AruviX" (Length 6)
la     a0, test_str2
call   strlen
# a0 = 6. Convert to '6'
addi   t0, a0, 48
sb     t0, 0(s1)
li     t1, 10
sb     t1, 0(s1)

ebreak

# strlen implementation (The user's code)
strlen:
li     t0, 0         # i = 0
1: # Start of for loop
add    t1, t0, a0    # Add the byte offset for str[i]
lb     t1, 0(t1)     # Dereference str[i]
beqz   t1, 1f        # if str[i] == 0, break for loop
addi   t0, t0, 1     # Add 1 to our iterator
j      1b            # Jump back to condition (1 backwards)
1: # End of for loop
mv     a0, t0        # Move t0 into a0 to return
ret                  # Return back via the return address register.

.data
test_str1: .string "Hello"
test_str2: .string "AruviX"