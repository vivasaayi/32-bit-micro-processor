/*
 * Very basic test for enhanced C compiler
 * Tests struct and malloc without parameters
 */

// Simple structure
struct TestStruct {
    int value;
    int count;
};

int main() {
    // Test sizeof
    int struct_size = sizeof(struct TestStruct);
    
    // Test malloc
    int ptr = malloc(struct_size);
    struct TestStruct* test = (struct TestStruct*)ptr;
    
    // Test struct member access
    test->value = 42;
    test->count = 10;
    
    int result = test->value + test->count;
    
    free(ptr);
    
    return result;
}
