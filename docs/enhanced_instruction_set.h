// Enhanced instruction set additions for data structure support

// Additional opcodes needed:
typedef enum {
    // Existing opcodes (0x01-0x1F) ...
    
    // Memory operations for data structures
    OP_LOADW  = 0x20,  // Load word (32-bit)
    OP_LOADH  = 0x21,  // Load halfword (16-bit)
    OP_LOADB  = 0x22,  // Load byte (8-bit)
    OP_STOREW = 0x23,  // Store word (32-bit)
    OP_STOREH = 0x24,  // Store halfword (16-bit)
    OP_STOREB = 0x25,  // Store byte (8-bit)
    
    // Pointer arithmetic
    OP_LEA    = 0x26,  // Load effective address
    OP_ADDPTR = 0x27,  // Add to pointer (scaled by type size)
    
    // Stack operations for function calls
    OP_PUSHM  = 0x28,  // Push multiple registers
    OP_POPM   = 0x29,  // Pop multiple registers
    
    // Comparison enhancements
    OP_CMPI   = 0x2A,  // Compare immediate
    OP_TEST   = 0x2B,  // Test (AND without storing result)
    
    // Bit manipulation (useful for flags, sets)
    OP_BSET   = 0x2C,  // Set bit
    OP_BCLR   = 0x2D,  // Clear bit
    OP_BTST   = 0x2E,  // Test bit
    
    // Loop support
    OP_LOOP   = 0x2F,  // Decrement and branch if not zero
    
} enhanced_opcode_t;

// Example usage in assembly for common data structure operations:

/*
Bubble Sort Algorithm Support:
```assembly
bubble_sort:
    ; for (i = 0; i < n-1; i++)
    LOADI R1, #0                ; i = 0
outer_loop:
    SUB R2, R10, R1             ; n - i
    SUBI R2, R2, #1             ; n - i - 1
    CMPI R2, #0                 ; compare with 0
    JLE sort_done               ; if <= 0, done
    
    ; for (j = 0; j < n-i-1; j++)  
    LOADI R3, #0                ; j = 0
inner_loop:
    CMP R3, R2                  ; compare j with n-i-1
    JGE next_i                  ; if j >= n-i-1, next i
    
    ; Load arr[j] and arr[j+1]
    LEA R4, array_base          ; base address
    ADDPTR R5, R4, R3           ; address of arr[j]
    LOADW R6, R5                ; load arr[j]
    ADDI R7, R5, #4             ; address of arr[j+1]
    LOADW R8, R7                ; load arr[j+1]
    
    ; Compare and swap if needed
    CMP R6, R8                  ; compare arr[j] with arr[j+1]
    JLE no_swap                 ; if arr[j] <= arr[j+1], no swap
    
    ; Swap elements
    STOREW R7, R6               ; arr[j+1] = arr[j]
    STOREW R5, R8               ; arr[j] = arr[j+1]
    
no_swap:
    ADDI R3, R3, #1             ; j++
    JMP inner_loop
    
next_i:
    ADDI R1, R1, #1             ; i++
    JMP outer_loop
    
sort_done:
    RET
```

Linked List Traversal:
```assembly
list_traverse:
    ; struct Node* current = head;
    MOVE R1, R10                ; current = head
    
traverse_loop:
    ; while (current != NULL)
    CMPI R1, #0                 ; compare current with NULL
    JZ traverse_done            ; if NULL, done
    
    ; Process current->data
    LOADW R2, R1                ; load current->data (offset 0)
    ; ... process data in R2 ...
    
    ; current = current->next
    ADDI R3, R1, #4             ; address of current->next (offset 4)
    LOADW R1, R3                ; current = current->next
    
    JMP traverse_loop
    
traverse_done:
    RET
```

Binary Search Tree Search:
```assembly
bst_search:
    ; Node* search(Node* root, int key)
    ; R10 = root, R11 = key, return result in R1
    
    MOVE R1, R10                ; current = root
    
search_loop:
    CMPI R1, #0                 ; if (current == NULL)
    JZ not_found                ; return NULL
    
    LOADW R2, R1                ; load current->data
    CMP R2, R11                 ; compare data with key
    JZ found                    ; if equal, found
    JLT search_right            ; if data < key, go right
    
search_left:
    ADDI R3, R1, #4             ; address of current->left
    LOADW R1, R3                ; current = current->left
    JMP search_loop
    
search_right:
    ADDI R3, R1, #8             ; address of current->right  
    LOADW R1, R3                ; current = current->right
    JMP search_loop
    
found:
    ; R1 already contains the node pointer
    RET
    
not_found:
    LOADI R1, #0                ; return NULL
    RET
```
*/
