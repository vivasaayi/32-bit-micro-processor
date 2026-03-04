/* Simplified stack-based virtual machine for our C compiler */

int stack[100];
int stack_pointer = 0;

void push(int value) {
    stack[stack_pointer] = value;
    stack_pointer = stack_pointer + 1;
}

int pop() {
    stack_pointer = stack_pointer - 1;
    return stack[stack_pointer];
}

int add_operation() {
    int b = pop();
    int a = pop();
    int result = a + b;
    push(result);
    return result;
}

int multiply_operation() {
    int b = pop();
    int a = pop();
    int result = a * b;
    push(result);
    return result;
}

int execute_bytecode() {
    push(5);      /* ICONST_5 */
    push(3);      /* ICONST_3 */
    push(2);      /* ICONST_2 */
    multiply_operation();  /* IMUL - 3 * 2 = 6 */
    add_operation();       /* IADD - 5 + 6 = 11 */
    return pop(); /* IRETURN */
}

int main() {
    int result = execute_bytecode();
    return result;
}
