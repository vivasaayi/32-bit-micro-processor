; Test hex parsing
LI x10, 0x2000
LI x1, 0x0F0F
SW x1, 0(x10)
LI x2, 0xF0F0  
SW x2, 4(x10)
HALT