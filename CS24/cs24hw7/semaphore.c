/*
 * General implementation of semaphores.
 *
 *--------------------------------------------------------------------
 * Adapted from code for CS24 by Jason Hickey.
 * Copyright (C) 2003-2010, Caltech.  All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <assert.h>

#include "sthread.h"
#include "semaphore.h"

/*
 * Element of the semaphore doubly-linked list, contains
 * a thread pointer to a thread that was blocked by this semaphore
 * as well as pointers to the previous and next elements in the list. 
 */

struct _semqueue {
    Thread *elem;
    struct _semqueue *prev;
    struct _semqueue *next;
};

/*
 * The semaphore data structure contains an int which represents the 
 * value of the semaphore, and a doubly-linked list which holds the 
 * threads that are blocked by this semaphore.
 */

struct _semaphore {
    int i;
    SemQueue *blocked_head;
    SemQueue *blocked_tail;
};

/* Check to see if the semaphore has blocked any threads */
static int semp_empty(Semaphore *semp) {
    assert(semp != NULL);
    return (semp->blocked_head == NULL);
}

/*
 * Package the thread pointer into a SemQueue node, and put that
 * node in the doubly-linked list for the given semaphore. 
 */
static void semp_append(Semaphore *semp, Thread *threadp) {
    assert(semp != NULL);
    assert(threadp != NULL);
    SemQueue *semq = (SemQueue *) malloc(sizeof(SemQueue));
    semq->elem = threadp;
    semq->prev = semp->blocked_tail;
    semq->next = NULL;
    if(semp->blocked_head == NULL) {
        semp->blocked_head = semq;
        semp->blocked_tail = semq;
    }
    else {
        semp->blocked_tail->next = semq;
        semp->blocked_tail = semq;
    }
}

/*
 * Remove the "top" thread that this semaphore blocked, and
 * return it. If the semaphore has no blocked threads, return
 * NULL.
 */
static Thread *queue_take(Semaphore *semp) {
    SemQueue *semq;

    assert(semp != NULL);

    /* Return NULL if the semaphore has no blocked threads. */
    if(semp->blocked_head == NULL)
        return NULL;

    /* Go to the final element */
    semq = semp->blocked_head;
    if(semq == semp->blocked_tail) {
        semp->blocked_head = NULL;
        semp->blocked_tail = NULL;
    }
    else {
        semq->next->prev = NULL;
        semp->blocked_head = semq->next;
    }
    return semq->elem;
}

/************************************************************************
 * Top-level semaphore implementation.
 */

/*
 * Allocate a new semaphore.  The initial value of the semaphore is
 * specified by the argument.
 */
Semaphore *new_semaphore(int init) {
    Semaphore *semp;
    semp = (Semaphore *) malloc(sizeof(Semaphore));
    semp->i = init;
    semp->blocked_head = NULL;
    semp->blocked_tail = NULL;
    return semp;
}

/*
 * Decrement the semaphore.
 * This operation must be atomic, and it blocks iff the semaphore is zero.
 */
void semaphore_wait(Semaphore *semp) {
    /* We ensure this operation is atomic by locking here. */
    __sthread_lock();
    while (semp->i == 0)
    {
        semp_append(semp, sthread_current());
        sthread_block();
        /* Block unlocks the thread, so we re-lock to prevent the thread
         from switching during decrementation. */
        __sthread_lock();
    }
    semp->i--;
    /* Waiting is finished, so we no longer need to be locked. */
    __sthread_unlock();
}

/*
 * Increment the semaphore.
 * This operation must be atomic.
 */
void semaphore_signal(Semaphore *semp) {
    /* We ensure this operation is atomic by locking here. */
    __sthread_lock();
    semp->i++;
    if (semp_empty(semp) == 0)
    {
        Thread *unblock_this = queue_take(semp);
        /* We remove the "top" thread of this semaphore
         from the queue of blocked threads */ 
        sthread_unblock(unblock_this);
    }
    /* Signaling is finished, so we no longer need to be locked. */
    __sthread_unlock();
    }
 