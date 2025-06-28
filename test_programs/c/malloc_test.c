/*
 * Memory allocation test for JVM
 * Tests malloc and sizeof with structs
 */

struct Node {
    int data;
    int next_ptr;
};

int main() {
    // Test sizeof with struct
    int node_size = sizeof(struct Node);
    
    // Test malloc 
    int ptr1 = malloc(node_size);
    int ptr2 = malloc(node_size);
    
    // Create two nodes using malloc'd memory
    struct Node* node1 = (struct Node*)ptr1;
    struct Node* node2 = (struct Node*)ptr2;
    
    // Set values
    node1->data = 100;
    node1->next_ptr = ptr2;
    
    node2->data = 200;
    node2->next_ptr = 0;
    
    // Test the linked structure
    int first_data = node1->data;
    int second_ptr = node1->next_ptr;
    
    struct Node* second_node = (struct Node*)second_ptr;
    int second_data = second_node->data;
    
    // Cleanup
    free(ptr1);
    free(ptr2);
    
    // Verify correct data was stored and retrieved
    if (first_data == 100 && second_data == 200) {
        return 1;  // Success
    } else {
        return 0;  // Failure
    }
}
