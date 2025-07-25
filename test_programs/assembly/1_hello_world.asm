#
# Risc-V Assembler program to print "Hello RISC-V World!"
# to stdout.
#
# a0-a2 - parameters to linux function services
# a7 - linux function number
#
.global _start      # Provide program starting address to linker
# Setup the parameters to print hello world
# and then call Linux to do it.
_start: addi  a0, x0, 1      # 1 = StdOut
        la    a1, helloworld # load address of helloworld
        addi  a2, x0, 20     # length of our string
        addi  a7, x0, 64     # linux write system call
        ecall                # Call linux to output the string
# Setup the parameters to exit the program
# and then call Linux to do it.
        addi    a0, x0, 0   # Use 0 return code
        addi    a7, x0, 93  # Service command code 93 terminates
        ecall               # Call linux to terminate the program
.data
helloworld:      .ascii "Hello RISC-V World!\n"
Listing 1-1The Linux version of the Hello World program