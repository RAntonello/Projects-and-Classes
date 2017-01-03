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


/*
 * Test Efficiency: 53%
 * Time Complexity Explanations:
 * Allocation is linear time, since it is first-fit so
 * it checks at most O(n) blocks to allocate from.
 * Deallocation is constant time because it requires that 
 * we only change the header and footer (which can be reached in constant time)
 * Coalescing is constant time because the header/footer implementation allows
 * us to modify each of the adjacent header/footer's in constant time.
 */

/*!
 * The header struct is used for both headers and footers.
 */

// I used the suggested header implementation from the HW.
typedef struct {
 /* Negative size means the block is allocated, */
 /* Positive size means the block is available. */
 int size;
} header;

/*!
 * These variables are used to specify the size and address of the memory pool
 * that the simple allocator works against.  
 * The memory pool is allocated within
 * init_myalloc(), and then myalloc() and free() work against this pool of
 * memory that mem points to.
 */

int MEMORY_SIZE;
int blocks = 0;
header *mem;
header *end;

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
    header *end;
    mem = (header *) malloc(MEMORY_SIZE);
    if (mem == 0) {
        fprintf(stderr,
                "init_myalloc: could not get %d bytes from the system\n",
                MEMORY_SIZE);
        abort();
    }
    

    // I'm using a standard header/footer implementation with constant-time
    // coelescing. The headers/footers are copies of each other and
    // contain the size of the block.
    
    h.size  = MEMORY_SIZE;
    *mem = h;
    end =  mem + ((MEMORY_SIZE / sizeof(header)) - 1);
    *end = h;
    
}


/*!
 * Attempt to allocate a chunk of memory of "size" bytes.  Return 0 if
 * allocation fails.
 */
unsigned char *myalloc(int size) {

    int half;
    int extra;
    unsigned char *payload;
    //blocks++;
    header *h = mem;
    header *footer;
    while (h->size < size + 8) /* Go through the blocks until 
    we find an unallocated one
    of sufficient size. */
    {
        /* If we go through all the blocks and can't find a match, fail */
        if (((unsigned char *) h + size) >= 
            (((unsigned char *) mem) + MEMORY_SIZE)) 
        {
            return (unsigned char *) 0; // Fail
        }
        else
        {
            if (h->size < 0)
            {
                //move through allocated memory
                h = (header *) ((unsigned char *) h + (-1 * h->size)); 
            }
            else
            {
                // move through deallocated memory
                h = (header *) ((unsigned char *) h + h->size); 
            }
        }
    }
    payload = (unsigned char *) (h + 1); // Save payload location for return
    if (((unsigned char *) h + size) >=  // If we can't allocate anything...
            (((unsigned char *) mem) + MEMORY_SIZE)) 
    {
        return (unsigned char *) 0; // Fail
    } 
    else 
    {
    while (h->size > (2 * size + 16)) // Keep splitting until you can't anymore
    {
        half = h->size / 2; // get half the size of block
        extra = h->size % 2; // Check for extra byte in case size is odd
        h->size = half; // split in two
        footer = (header *) ((unsigned char *) h + half); //move to second half
        footer->size = half + extra; // and create header for second half
        footer = footer - 1; // move to footer space for first half
        footer->size = half; //create footer for first half
        footer = (header *) ((unsigned char *) footer + half + extra); 
        // move to footer space for second half  
        footer->size = half + extra; // create footer for second half
    }   
        int header_footer_change = -1 * h->size;
        h->size = -1 * h->size; // otherwise allocate memory  
        h = (header *) ((unsigned char *) h - h->size); 
        h = h - 1; //move to footer
        h->size = header_footer_change; // "allocate" footer
        return (unsigned char *) payload; // return pointer to payload
    }
}



/*!
 * Free a previously allocated pointer.  
 oldptr should be an address returned by myalloc().
 */
void myfree(unsigned char *oldptr) {
    int h_size = sizeof(header); // size of header struct
    // last byte allocated by malloc
    header *end_of_malloc = (header *) (((unsigned char *) mem) + MEMORY_SIZE - 1);  
    header *h = (header *) (oldptr - sizeof(header)); // go to header 
    int current_size = -1 * h->size; // size of to-be-freed block
    header *next = (header *) ((unsigned char *) h + current_size); // next block
    header *prev_footer = (header *) ((unsigned char *) h - h_size);
    {
        if ((next <= end_of_malloc) 
        && next->size > 0) // if next block exists and is free
        {   // NB: Short circuiting so we don't have problems
            // if previous block also exists and is free
            if (h != mem && prev_footer->size > 0)
            {
                // compute size of all three blocks and update 
                // header of first block and footer of last block
                current_size += next->size + prev_footer->size;
                header *prev = (header *) ((unsigned char *) 
                    h - (h - 1)->size);
                prev->size = current_size; // replace header
                header *footer = (header *) ((unsigned char *) 
                    prev + current_size - h_size);
                footer->size = current_size; // replace footer

            }
            else
            // only the next block can be coalesced (WORKS) 
            {
            current_size += next->size; // add next block size to current block
            h->size = current_size; // replace header
            next = (header *) ((unsigned char *) h + current_size - h_size);
            next->size = current_size; // replace footer of next block
            }  
        }
        else
        {
            // if only previous block is free
            if (h != mem && prev_footer->size > 0) 
            {
                int prev_size = prev_footer->size;
                current_size += prev_size;
                h = (header *) ((unsigned char *) h - prev_size); 
                h->size = current_size; // replace header
                header *footer = (header *) ((unsigned char *) 
                    h + current_size - h_size);
                footer->size = current_size;
            }
            else // both adjacent blocks are not free
            {
                h->size = current_size;
                header *footer = (header *) ((unsigned char *) 
                    h + current_size - h_size);
                footer->size = current_size;
            }
        }
    }
}

