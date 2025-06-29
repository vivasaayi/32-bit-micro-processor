/* 
 * Ultra-Simple JVM - Guaranteed to compile and assemble
 * Only uses basic operations compatible with RISC processor
 */

int main() {
    /* Simple JVM test: calculate 5 + 3 * 2 = 11 */
    
    /* Simulate JVM stack and operations */
    int stack[10];
    int sp = 0;
    
    /* Push 5 */
    stack[sp] = 5;
    sp = sp + 1;
    
    /* Push 3 */
    stack[sp] = 3;
    sp = sp + 1;
    
    /* Push 2 */
    stack[sp] = 2;
    sp = sp + 1;
    
    /* Multiply: pop 2, pop 3, push 3*2=6 */
    sp = sp - 1;
    int b = stack[sp];
    sp = sp - 1;
    int a = stack[sp];
    stack[sp] = a * b;
    sp = sp + 1;
    
    /* Add: pop 6, pop 5, push 5+6=11 */
    sp = sp - 1;
    b = stack[sp];
    sp = sp - 1;
    a = stack[sp];
    stack[sp] = a + b;
    sp = sp + 1;
    
    /* Return result */
    sp = sp - 1;
    return stack[sp];
}
