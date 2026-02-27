// Example Java programs that can be compiled and run on AruviJVM

// Example 1: Simple arithmetic
public class SimpleArithmetic {
    public static int calculate() {
        return 5 + 3 * 2;
    }
}

// Example 2: Factorial function (iterative)
public class Factorial {
    public static int factorial(int n) {
        int result = 1;
        int i = 1;
        while (i <= n) {
            result = result * i;
            i = i + 1;
        }
        return result;
    }
}

// Example 3: Greatest Common Divisor (Euclidean algorithm)
public class GCD {
    public static int gcd(int a, int b) {
        while (b != 0) {
            int temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }
}

// Example 4: Simple sorting (bubble sort)
public class BubbleSort {
    public static void sort(int[] arr, int length) {
        int i = 0;
        while (i < length - 1) {
            int j = 0;
            while (j < length - i - 1) {
                if (arr[j] > arr[j + 1]) {
                    // Swap elements
                    int temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
                j = j + 1;
            }
            i = i + 1;
        }
    }
}

// Example 5: Linear search
public class LinearSearch {
    public static int search(int[] arr, int length, int target) {
        int i = 0;
        while (i < length) {
            if (arr[i] == target) {
                return i;  // Found at index i
            }
            i = i + 1;
        }
        return -1;  // Not found
    }
}

/*
 * Compilation instructions:
 * 
 * 1. Compile with javac:
 *    javac SimpleArithmetic.java
 * 
 * 2. Disassemble with javap to see bytecode:
 *    javap -c SimpleArithmetic
 * 
 * 3. Extract the bytecode and convert to AruviJVM format
 * 
 * The AruviJVM currently supports these basic operations, so more complex
 * programs will need additional opcodes to be implemented.
 */
