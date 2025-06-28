/*
 * Very simple JVM test without function parameters
 */

struct JVM {
    int values[8];
    int sp;
};

int main() {
    struct JVM jvm;
    jvm.sp = 0;
    
    /* Manual stack operations */
    jvm.values[0] = 10;
    jvm.values[1] = 5;
    jvm.sp = 2;
    
    /* Pop and add */
    jvm.sp = jvm.sp - 1;
    int b = jvm.values[jvm.sp];
    jvm.sp = jvm.sp - 1;  
    int a = jvm.values[jvm.sp];
    
    int result = a + b;
    
    return result;
}
