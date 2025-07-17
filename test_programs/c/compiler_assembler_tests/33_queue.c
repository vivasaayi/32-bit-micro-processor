// 33_queue.c
#include <stdio.h>
#define N 5
int queue[N], front = 0, rear = 0;
void enqueue(int x) { if ((rear+1)%N != front) { queue[rear] = x; rear = (rear+1)%N; } }
int dequeue() { if (front != rear) { int x = queue[front]; front = (front+1)%N; return x; } return -1; }
int main() {
    enqueue(1); enqueue(2); enqueue(3);
    printf("%d %d %d\n", dequeue(), dequeue(), dequeue());
    return 0;
}
