# Test register parsing
LI x5, 0x2000
LI x28, 42
SW x28, 0(x5)
HALT