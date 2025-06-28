/*
 * Working JVM interpreter - simplified for current C compiler capabilities
 * Tests basic JVM operations without arrays in structs
 */

// Java bytecode constants (simplified)

// Simple JVM state
struct SimpleJVM {
    int stack0;
    int stack1;
    int sp;
    int local0;
    int local1;
};

// Push value to stack (simplified)
void push_value(struct SimpleJVM* jvm, int value) {
    if (jvm->sp == 0) {
        jvm->stack0 = value;
        jvm->sp = 1;
    } else if (jvm->sp == 1) {
        jvm->stack1 = value;
        jvm->sp = 2;
    }
}

// Pop value from stack (simplified)
int pop_value(struct SimpleJVM* jvm) {
    if (jvm->sp == 2) {
        jvm->sp = 1;
        return jvm->stack1;
    } else if (jvm->sp == 1) {
        jvm->sp = 0;
        return jvm->stack0;
    }
    return 0;
}

// Execute simple Java bytecode
int execute_simple_java() {
    struct SimpleJVM jvm;
    jvm.sp = 0;
    jvm.local0 = 0;
    jvm.local1 = 0;
    
    // Simulate: iconst_3, iconst_5, iadd, ireturn
    // This is equivalent to: return 3 + 5;
    
    // iconst_3: push 3
    push_value(&jvm, 3);
    
    // iconst_5: push 5  
    push_value(&jvm, 5);
    
    // iadd: pop two values, add, push result
    int b = pop_value(&jvm);
    int a = pop_value(&jvm);
    int result = a + b;
    push_value(&jvm, result);
    
    // ireturn: return top of stack
    return pop_value(&jvm);
}

int main() {
    int result = execute_simple_java();
    return result;  // Should return 8 (3 + 5)
}
