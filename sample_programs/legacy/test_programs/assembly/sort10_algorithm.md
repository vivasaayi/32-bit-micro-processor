# Bubble Sort Algorithm for 10 Registers (R1-R10)

This program demonstrates how to sort 10 values using only registers and the tested instruction set (LOADI, ADD, SUB, CMP, JZ, JLT, JMP, STORE). The approach is a hand-unrolled bubble sort, using explicit register names for each array element.

## Register Usage
- **R1–R10:** Input array (unsorted values)
- **R11–R20:** Output array (sorted values, sorted in-place)
- **R21:** Temporary register for swapping
- **R22:** Register for comparison result
- **R0:** Always zero (cannot be used for data)

## Algorithm Steps
1. **Load Input:**
   - Load 10 unsorted values into R1–R10.
2. **Copy to Output:**
   - Copy R1–R10 to R11–R20 for sorting.
3. **Bubble Sort (Hand-Unrolled):**
   - For each pass (total 9 passes for 10 elements):
     - Compare each adjacent pair (R11 & R12, R12 & R13, ..., R19 & R20).
     - If the left register is greater than the right, swap them using R21 as a temporary.
     - Use SUB, CMP, JZ, and JLT to implement the conditional swap.
   - Each pass moves the largest remaining value to the rightmost unsorted position.
   - The code is unrolled: each compare/swap is written explicitly, as indirect register addressing is not available.
4. **Store Sorted Output:**
   - Store R11–R20 to memory addresses 0x1000, 0x1004, ..., 0x1024.
5. **End Program:**
   - HALT instruction.

## Notes
- The program is written for a fixed array size (10 elements) and does not use loops or indirect addressing.
- To fully sort, all 9 passes must be written out (only the first pass is shown in the sample for brevity).
- This approach is feasible for small arrays and demonstrates register-based sorting on a simple RISC architecture.

---

**See `sort10.asm` for the code implementation.**
