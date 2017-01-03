/*============================================================================
 * Implementation of the FIFO page replacement policy.
 *
 * We don't mind if paging policies use malloc() and free(), just because it
 * keeps things simpler.  In real life, the pager would use the kernel memory
 * allocator to manage data structures, and it would endeavor to allocate and
 * release as little memory as possible to avoid making the kernel slow and
 * prone to memory fragmentation issues.
 */

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include "vmpolicy.h"


/*============================================================================
 * "PageQueue" Data Structure
 *
 * This data structure is simply a doubly linked list of pages, with a head and 
 * a tail. When we map a page, we add it to the end of the queue, and when we
 * evict a victim, we remove it from the head of the queue.
 */

typedef struct _pagequeue {
    page_t  page;
    struct _pagequeue *prev;
    struct _pagequeue *next;
} PageQueue;

typedef struct _linkedlist {
    int max_resident;
    int num_loaded;
    PageQueue *head;
    PageQueue *tail;
} LinkedList;



/*============================================================================
 * Policy Implementation
 */


/* The queue of pages that are currently resident. */
static LinkedList *loaded;


/* Initialize the policy.  Return nonzero for success, 0 for failure. */
int policy_init(int max_resident) {
    fprintf(stderr, "Using FIFO eviction policy.\n\n");
    
    loaded = malloc(sizeof(LinkedList));
    if (loaded) {
        loaded->max_resident = max_resident;
        loaded->num_loaded = 0;
        loaded->head = NULL;
        loaded->tail = NULL;
    }

    
    /* Return nonzero if initialization succeeded. */
    return (loaded != NULL);
}


/* Clean up the data used by the page replacement policy. */
void policy_cleanup(void) {
    PageQueue *next;
    while(loaded->head != NULL)
    {
        next = loaded->head->next;
        free(loaded->head);
        loaded->head = next;
    }
    free(loaded);
    loaded = NULL;
}


/* This function is called when the virtual memory system maps a page into the
 * virtual address space.  Record that the page is now resident by adding it to
 * the tail of the queue. 
 */
void policy_page_mapped(page_t page) {
    assert(loaded->num_loaded < loaded->max_resident);
    PageQueue *node = (PageQueue *) malloc(sizeof(PageQueue));
    node->page = page;
    node->prev = loaded->tail;
    if (loaded->head == NULL)
    {
        loaded->head = node;
        loaded->tail = node;
    }
    else
    {
        loaded->tail->next = node;
        loaded->tail = node;  
    }
    loaded->num_loaded++;
}


/* This function is called when the virtual memory system has a timer tick. */
void policy_timer_tick(void) {
    /* Do nothing! */
}


/* Choose a page to evict from the collection of mapped pages.  Then, record
 * that it is evicted.  We simply evict the head of the queue and readjust the
 * linked list.
 */
page_t choose_and_evict_victim_page(void) {
    page_t victim;
    PageQueue *next;

    /* We evict the first page to enter the queue that is still in the queue
    (i.e. we evict the head of the queue) . */
    victim = loaded->head->page;

    loaded->head->next->prev = NULL;
    next = loaded->head->next;
    free(loaded->head);
    loaded->head = next;
    loaded->num_loaded--;

#if VERBOSE
    fprintf(stderr, "Choosing victim page %u to evict.\n", victim);
#endif

    return victim;
}

