#include <stdio.h>
#include "sthread.h"


/* 
 * This thread-function loops "arg" times, yielding 
 * after each loop.
 */
static void loop_if_positive(void *arg) {
    int i;
    int iter_count = (int)arg;
    printf("Thread-function %d is going to loop %d times...\n", 
        iter_count / 2, iter_count);
    for (i = 1; i <= iter_count; ++i)
    {
        printf("This is loop %d of thread-function %d.\n", i,  iter_count / 2);
        sthread_yield(); // After every loop, yield.
    }
        printf("Thread-function %d finished!\n", iter_count / 2);
        return; // Once the thread-function is complete, return.
}


/*
 * The main function starts the four threads, which loop
 * 2, 4, 6, and 8 times respectively.
 */
int main(int argc, char **argv) {
    sthread_create(loop_if_positive, (void *) 2); // Loop 1 runs 2 times.
    sthread_create(loop_if_positive, (void *) 4); // Loop 2 runs 4 times.
    sthread_create(loop_if_positive, (void *) 6); // Loop 3 runs 6 times.
    sthread_create(loop_if_positive, (void *) 8); // Loop 4 runs 8 times.
    sthread_start();
    return 0;
}


