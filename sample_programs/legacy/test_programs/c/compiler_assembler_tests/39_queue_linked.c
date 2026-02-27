// 39_queue_linked.c
#include <stdio.h>
#include <stdlib.h>
typedef struct Node {
    int val;
    struct Node* next;
} Node;
typedef struct {
    Node* front;
    Node* rear;
} Queue;
void enqueue(Queue* q, int v) {
    Node* n = malloc(sizeof(Node)); n->val = v; n->next = NULL;
    if (!q->rear) q->front = q->rear = n;
    else { q->rear->next = n; q->rear = n; }
}
int dequeue(Queue* q) {
    if (!q->front) return -1;
    int v = q->front->val;
    Node* n = q->front; q->front = n->next;
    if (!q->front) q->rear = NULL;
    free(n);
    return v;
}
int main() {
    Queue q = {0,0};
    enqueue(&q, 1); enqueue(&q, 2);
    printf("%d %d\n", dequeue(&q), dequeue(&q));
    return 0;
}
