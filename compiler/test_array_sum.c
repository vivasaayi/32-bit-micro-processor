int sum_array() {
    int numbers[3];
    numbers[0] = 10;
    numbers[1] = 20;
    numbers[2] = 30;
    
    int total = numbers[0] + numbers[1] + numbers[2];
    return total;
}

int main() {
    int result = sum_array();
    return result;
}
