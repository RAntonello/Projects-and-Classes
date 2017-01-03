/*0
 * Define a bounded buffer containing records that describe the
 * results in a producer thread.
 *
 *--------------------------------------------------------------------
 * Adapted from code for CS24 by Jason Hickey.
 * Copyright (C) 2003-2010, Caltech.  All rights reserved.
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <memory.h>

#include "sthread.h"
#include "bounded_buffer.h"
#include "semaphore.h"

/*
 * The bounded buffer data.
 */
struct _bounded_buffer {
    /* The maximum number of elements in the buffer */
    int length;

    /* The index of the first element in the buffer */
    int first;

    /* The number of elements currently stored in the buffer */
    int count;

    /* Semaphore for determining if buffer is full */
    Semaphore *full;

    /* Semaphore for determining if buffer is empty */
    Semaphore *empty;

    /* Semaphore (mutex) for preventing multiple threads are 
      modifying the buffer at the same time. */
    Semaphore *buff_protect;

    /* The values in the buffer */
    BufferElem *buffer;
};

/*
 * For debugging, ensure that empty slots in the buffer are
 * set to a default value.
 */
static BufferElem empty = { -1, -1, -1 };

/*
 * Allocate a new bounded buffer.
 */
BoundedBuffer *new_bounded_buffer(int length) {
    BoundedBuffer *bufp;
    BufferElem *buffer;
    int i;

    /* Allocate the buffer */
    buffer = (BufferElem *) malloc(length * sizeof(BufferElem));
    bufp = (BoundedBuffer *) malloc(sizeof(BoundedBuffer));
    if (buffer == 0 || bufp == 0) {
        fprintf(stderr, "new_bounded_buffer: out of memory\n");
        exit(1);
    }

    /* Initialize */

    memset(bufp, 0, sizeof(BoundedBuffer));

    for (i = 0; i != length; i++)
        buffer[i] = empty;

    bufp->length = length;
    bufp->buffer = buffer;
    bufp->full = new_semaphore(length);
    bufp->empty = new_semaphore(0);
    bufp->buff_protect = new_semaphore(1);

    return bufp;
}

/*
 * Add an integer to the buffer.  Yield control to another
 * thread if the buffer is full.
 */
void bounded_buffer_add(BoundedBuffer *bufp, const BufferElem *elem) {
    /* Wait until the buffer has space */
    semaphore_wait(bufp->full);

    /* Ensure that the buffer is not being modified in a different thread. */
    semaphore_wait(bufp->buff_protect);
    /* Now the buffer has space */
    bufp->buffer[(bufp->first + bufp->count) % bufp->length] = *elem;
    bufp->count++;
    /* Threads waiting for a value to retrieve are good to go! */
    semaphore_signal(bufp->empty);
    /* Buffer is no longer being acccesed, so we signal the mutex. */
    semaphore_signal(bufp->buff_protect);
}

/*
 * Get an integer from the buffer.  Block the current thread
 * if the buffer is empty.
 */
void bounded_buffer_take(BoundedBuffer *bufp, BufferElem *elem) {
    /* Wait until the buffer has a value to retrieve */
    semaphore_wait(bufp->empty);

    /* Ensure that the buffer is not being modified in a different thread. */
    semaphore_wait(bufp->buff_protect);
    /* Copy the element from the buffer, and clear the record */
    *elem = bufp->buffer[bufp->first];
    bufp->buffer[bufp->first] = empty;
    bufp->count--;
    /* Threads waiting for space to store a value are good to go! */
    semaphore_signal(bufp->full);
    bufp->first = (bufp->first + 1) % bufp->length;
    /* Buffer is no longer being acccesed, so we signal the mutex. */
    semaphore_signal(bufp->buff_protect);
}


