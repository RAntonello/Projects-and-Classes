#include <stdio.h>
#include "sthread.h"


/*! This thread-function checks to see if its 
input argument is 1, as it should be. */
static void test1(void *arg) {
    while(1) {
        int i = (int)arg;
        if (i == 1)
        {
            printf("Test #1 succeeded!\n");
            return;
        }
        else
        {
            printf("Test #1 failed! Argument was %d, but expected 1.\n", i);
            return;
        }
    }
}

/*! This thread-function checks to see if its 
input argument is 2, as it should be. */
static void test2(void *arg) {
    while(1) {
        int i = (int)arg;
        if (i == 2)
        {
            printf("Test #2 succeeded!\n");
            return;
        }
        else
        {
            printf("Test #2 failed! Argument was %d, but expected 2.\n", i);
            return;
        }
    }
}


/*
 * The main function starts the two test thread-functions.
 */
int main(int argc, char **argv) {
    int i = 1;
    sthread_create(test1, (void *) i); // Pass 1 to test1
    sthread_create(test2, (void *) (i + 1)); // Pass 2 to test2
    sthread_start();
    return 0;
}
