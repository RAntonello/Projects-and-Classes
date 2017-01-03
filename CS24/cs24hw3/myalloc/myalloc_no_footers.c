/*! \file
 * Implementation of a simple memory allocator.  The allocator manages a small
 * pool of memory, provides memory chunks on request, and reintegrates freed
 * memory back into the pool.
 *
 * Adapted from Andre DeHon's CS24 2004, 2006 material.
 * Copyright (C) California Institute of Technology, 2004-2010.
 * All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>

#include "myalloc.h"


/*!
 * The header struct is used for both headers and footers.
 */

typedef struct {
 /* Negative size means the block is allocated, */
 /* positive size means the block is available. */
 int size;
} header;

/*!
 * These variables are used to specify the size and address of the memory pool
 * that the simple allocator works against.  The memory pool is allocated within
 * init_myalloc(), and then myalloc() and free() work against this pool of
 * memory that mem points to.
 */



int MEMORY_SIZE;
int blocks = 0;
header *mem;


/*!
 * This function initializes both the allocator state, and the memory pool.  It
 * must be called before myalloc() or myfree() will work at all.
 *
 * Note that we allocate the entire memory pool using malloc().  This is so we
 * can create different memory-pool sizes for testing.  Obviously, in a real
 * allocator, this memory pool would either be a fixed memory region, or the
 * allocator would request a memory region from the operating system (see the
 * C standard function sbrk(), for example).
 */
void init_myalloc() {

    /*
     * Allocate the entire memory pool, from which our simple allocator will
     * serve allocation requests.
     */
    header h;
    unsigned char *end;
    mem = (header *) malloc(MEMORY_SIZE);
    if (mem == 0) {
        fprintf(stderr,
                "init_myalloc: could not get %d bytes from the system\n",
                MEMORY_SIZE);
        abort();
    }

    /* TODO:  You can initialize the initial state of your memory pool here. */
    /* The memory pool will use the simple recommended allocation procedure, with
    a header and a footer.*/
    
    h.size  = MEMORY_SIZE;
    *mem = h;
    end = ((unsigned char *) mem) + (MEMORY_SIZE - sizeof(header));
    *end = h;
    
}


/*!
 * Attempt to allocate a chunk of memory of "size" bytes.  Return 0 if
 * allocation fails.
 */
unsigned char *myalloc(int size) {

    int half;
    int extra;
    //blocks++;
    header * h = mem;
    while (h->size < size + 8) /* Go through the blocks until we find an unallocated one
    of sufficient size. */
    {
        /* If we go through all the blocks and can't find a match, fail */
        if (((unsigned char *) h + size) >= (((unsigned char *) mem) + MEMORY_SIZE)) 
        {
            return (unsigned char *) 0; // Fail
        }
        else
        {
            if (h->size < 0)
            {
                h = (header *) ((unsigned char *) h + (-1 * h->size)); //move through allocated memory
            }
            else
            {
                h = (header *) ((unsigned char *) h + h->size); // move through deallocated memory
            }
        }
    }
    if (((unsigned char *) h + size) >= (((unsigned char *) mem) + MEMORY_SIZE)) 
    {
        return (unsigned char *) 0; // Fail
    }
    else if ((*h).size > (2 * size + 16)) // If large enough to split
    {
        extra = h->size % 2; // Check for extra byte in case size is odd
        half = h->size / 2; // Split in two
        (*h).size = -1 * half; // allocate first half
        h = (header *) ((unsigned char *) h + half); //move to second half
        (*(h - 1)).size = -1 * half; //create footer for first half 
        (*h).size = half + extra; // and create header for second half
        (*(h + half + extra - 1)).size = half + extra; 
        h = (header *) ((unsigned char *) h - half); //move back to second half
        return (unsigned char *) (h + 1); // and return pointer to payload
    }
    else
    {
        (*h).size = -1 * h->size; // otherwise allocate memory 
        return (unsigned char *) (h + 1); // return pointer to payload
    }
}



/*!
 * Free a previously allocated pointer.  oldptr should be an address returned by
 * myalloc().
 */
void myfree(unsigned char *oldptr) {
    header *h = (header *) (oldptr - sizeof(header));
    if ((*h).size < 0)
    {
        (*h).size *= -1; // Free memory block
    }
    else
    {
        printf("Memory already free!\n");
    }
    
}

