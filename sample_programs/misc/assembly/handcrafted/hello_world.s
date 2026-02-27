.global start

.org 0x8000

start:
li x4, 0x48656C6C  # "Hell" - was R0, but R0 is zero register
li x1, 0x6F20576F  # "o Wo"
li x2, 0x726C6421  # "rld!"

# Store message in memory at 0x6000
li x10, 0x6000
sw x4, 0(x10)
sw x1, 4(x10)
sw x2, 8(x10)

ebreak