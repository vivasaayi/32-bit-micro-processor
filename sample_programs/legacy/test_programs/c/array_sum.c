// Array processing
int sum_array(int arr[], int size) {
    int sum = 0;
    int i = 0;
    while (i < size) {
        sum = sum + arr[i];
        i = i + 1;
    }
    return sum;
}

int main() {
    int numbers[5];
    numbers[0] = 1;
    numbers[1] = 2;
    numbers[2] = 3;
    numbers[3] = 4;
    numbers[4] = 5;
    
    int total = sum_array(numbers, 5);
    return total;
}
