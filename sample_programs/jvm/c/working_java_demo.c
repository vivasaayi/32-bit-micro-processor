/*
 * Working Java JVM Execution Demo
 */

struct JVM {
    int data[8];
    int sp;
};

int main() {
    struct JVM jvm;
    int a;
    int b;
    int result;
    
    jvm.sp = 0;
    
    /* Java: int a = 10; int b = 5; return a + b; */
    
    /* Push 10 */
    jvm.data[0] = 10;
    
    /* Push 5 */
    jvm.data[1] = 5;
    
    /* Add them */
    a = jvm.data[0];
    b = jvm.data[1];
    result = a + b;
    
    return result;
}
