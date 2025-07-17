/* Ultra-simplified VM concept for our C compiler */

int stack_val1 = 0;
int stack_val2 = 0;
int stack_val3 = 0;

void push_to_slot1(int value) {
    stack_val1 = value;
}

void push_to_slot2(int value) {
    stack_val2 = value;
}

void push_to_slot3(int value) {
    stack_val3 = value;
}

int simple_vm_add() {
    return stack_val1 + stack_val2;
}

int simple_vm_multiply() {
    return stack_val2 * stack_val3;
}

int vm_execute() {
    push_to_slot1(5);    /* Load 5 */
    push_to_slot2(3);    /* Load 3 */
    push_to_slot3(2);    /* Load 2 */
    
    int temp = simple_vm_multiply(); /* 3 * 2 = 6 */
    push_to_slot2(temp);
    
    return simple_vm_add(); /* 5 + 6 = 11 */
}

int main() {
    int result = vm_execute();
    return result;
}
