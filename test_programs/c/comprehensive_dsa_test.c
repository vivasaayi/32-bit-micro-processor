/*
 * Comprehensive Data Structure and Algorithm Test Suite
 * Tests the processor's capability to handle common DSA problems
 */

#include <stdio.h>

// Test 1: Array operations (bubble sort)
int test_bubble_sort() {
    int arr[5] = {64, 34, 25, 12, 22};
    int n = 5;
    
    // Bubble sort implementation
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-i-1; j++) {
            if (arr[j] > arr[j+1]) {
                // Swap
                int temp = arr[j];
                arr[j] = arr[j+1];
                arr[j+1] = temp;
            }
        }
    }
    
    // Verify sorted: 12, 22, 25, 34, 64
    if (arr[0] == 12 && arr[1] == 22 && arr[2] == 25 && 
        arr[3] == 34 && arr[4] == 64) {
        return 1; // PASS
    }
    return 0; // FAIL
}

// Test 2: Recursive function (factorial)
int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

int test_factorial() {
    int result = factorial(5);
    return (result == 120) ? 1 : 0;
}

// Test 3: Pointer operations
int test_pointers() {
    int x = 42;
    int *ptr = &x;
    
    *ptr = 100;
    
    return (x == 100) ? 1 : 0;
}

// Test 4: Structure operations
struct Point {
    int x;
    int y;
};

int test_structures() {
    struct Point p1;
    p1.x = 10;
    p1.y = 20;
    
    struct Point *ptr = &p1;
    ptr->x = 30;
    
    return (p1.x == 30 && p1.y == 20) ? 1 : 0;
}

// Test 5: Linked list operations
struct Node {
    int data;
    struct Node* next;
};

int test_linked_list() {
    // Create nodes
    struct Node node1, node2, node3;
    
    node1.data = 1;
    node1.next = &node2;
    node2.data = 2;
    node2.next = &node3;
    node3.data = 3;
    node3.next = NULL;
    
    // Traverse and sum
    struct Node* current = &node1;
    int sum = 0;
    while (current != NULL) {
        sum += current->data;
        current = current->next;
    }
    
    return (sum == 6) ? 1 : 0;
}

// Test 6: Binary search
int binary_search(int arr[], int n, int target) {
    int left = 0;
    int right = n - 1;
    
    while (left <= right) {
        int mid = left + (right - left) / 2;
        
        if (arr[mid] == target) {
            return mid;
        }
        
        if (arr[mid] < target) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }
    
    return -1; // Not found
}

int test_binary_search() {
    int arr[7] = {2, 3, 4, 10, 40, 50, 80};
    int result = binary_search(arr, 7, 10);
    return (result == 3) ? 1 : 0;
}

// Main test runner
int main() {
    int total_tests = 0;
    int passed_tests = 0;
    
    // Run all tests
    total_tests++;
    if (test_bubble_sort()) passed_tests++;
    
    total_tests++;
    if (test_factorial()) passed_tests++;
    
    total_tests++;
    if (test_pointers()) passed_tests++;
    
    total_tests++;
    if (test_structures()) passed_tests++;
    
    total_tests++;
    if (test_linked_list()) passed_tests++;
    
    total_tests++;
    if (test_binary_search()) passed_tests++;
    
    // Write results to status register
    if (passed_tests == total_tests) {
        // All tests passed
        *((int*)0x2000) = 0x600D; // "GOOD" in hex
    } else {
        // Some tests failed
        *((int*)0x2000) = 0xFAD; // "FAD" (failed) in hex
    }
    
    return passed_tests;
}
