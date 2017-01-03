#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "multimap.h"


/*============================================================================
 * TYPES
 *
 *   These types are defined in the implementation file so that they can
 *   be kept hidden to code outside this source file.  This is not for any
 *   security reason, but rather just so we can enforce that our testing
 *   programs are generic and don't have any access to implementation details.
 *============================================================================*/

 /* Represents a value that is associated with a given key in the multimap. */
typedef struct multimap_value {
    int value;
} multimap_value;



/* Represents a key and its associated values in the multimap, as well as
 * pointers to the left and right child nodes in the multimap. */
typedef struct multimap_node {
    /* The key-value that this multimap node represents. */
    int key;

    /* The size of the array stored at this key */
    int size;

    /* An array of the values associated with this key in the multimap. */
    int *values;

    /* The left child of the multimap node.  This is the index of this node
    in the node array. It is set to -1 if no left child exists.
    int left_child_index; */

    int left_child_index;

    /* The right child of the multimap node.  This is the index of this node
    in the node array. It is set to -1 if no right child exists.
     */
    int right_child_index;

} multimap_node;

typedef struct multimap {
    /* The number of nodes in this array */
    int size;


    /*A pointer to the root node, which will populate index 0.*/
    multimap_node *root;
    
} multimap;


/*============================================================================
 * HELPER FUNCTION DECLARATIONS
 *
 *   Declarations of helper functions that are local to this module.  Again,
 *   these are not visible outside of this module.
 *============================================================================*/

multimap * alloc_mm_node(multimap *arr, int key);

int find_mm_node(multimap *arr, int key,
                             int create_if_not_found);

void free_multimap_values(int *values);


/*============================================================================
 * FUNCTION IMPLEMENTATIONS
 *============================================================================*/

/* Allocates a multimap node, and zeros out its contents so that we know what
 * the initial value of everything will be.
 */
multimap * alloc_mm_node(multimap *arr, int key) {
    arr->size++; 
    arr->root = (multimap_node *) realloc(arr->root, (sizeof(multimap_node) * (1 + arr->size)));
    multimap_node *node = &(arr->root[arr->size]);
    node->right_child_index = -1;
    node->left_child_index = -1;
    node->values = malloc(sizeof(int));
    node->key = key;
    node->size = 0;
    return arr;
}


/* This helper function searches for the multimap node that contains the
 * specified key.  If such a node doesn't exist, the function can initialize
 * a new node and add this into the structure, or it will simply return NULL.
 * The one exception is the root - if the root is NULL then the function will
 * return a new root node.
 */
int find_mm_node(multimap *arr, int key,
                             int create_if_not_found) {
    int node_i;
    /* If the entire multimap is empty, the root will be NULL. */
    if (arr->size == (-1)) {
        if (create_if_not_found) {
            arr = alloc_mm_node(arr, key);
        }
        return 0;
    }

    /* Now we know the multimap has at least a root node, so start there. */
    node_i = 0;
    while (1) {
        if (arr->root[node_i].key == key)
            break;

        if (arr->root[node_i].key > key) {   /* Follow left child */
            if (arr->root[node_i].left_child_index == -1 && create_if_not_found) {
                /* No left child, but caller wants us to create a new node. */
                arr = alloc_mm_node(arr, key);
                arr->root[node_i].left_child_index = arr->size;
            }
            node_i = arr->root[node_i].left_child_index;
        }
        else {                   /* Follow right child */
            if (arr->root[node_i].right_child_index == -1 && create_if_not_found) {
                /* No right child, but caller wants us to create a new node. */
                arr = alloc_mm_node(arr, key);
                arr->root[node_i].right_child_index = arr->size;
            }
            node_i = arr->root[node_i].right_child_index;
        }

        if (node_i == -1)
            break;
    }

    return node_i;
}


/* This helper function frees all values in a multimap node's value-list. */
void free_multimap_values(int *values) {
#ifdef DEBUG_ZERO
        /* Clear out what we are about to free, to expose issues quickly. */
        bzero(values, sizeof(multimap_value));
#endif
        free(values);
}

void free_multimap_node(multimap *mm, int node_i) {
    
    if (node_i == -1)
        return;
    multimap_node *node = &(mm->root[node_i]);
    /* Free the children first. */
    if (node->left_child_index != -1)
    {
        free_multimap_node(mm, node->left_child_index);
    }
    
    if (node->right_child_index != -1)
    {
        free_multimap_node(mm, node->right_child_index);
    }

    /* Free the list of values. */
    free_multimap_values(node->values);

#ifdef DEBUG_ZERO
    /* Clear out what we are about to free, to expose issues quickly. */
    bzero(node, sizeof(multimap_node));
#endif
}




/* Initialize a multimap data structure. */
multimap * init_multimap() {
    multimap *mm = malloc(sizeof(multimap));
    mm->size = -1;
    mm->root = malloc(sizeof(multimap_value));
    return mm;
}


/* Release all dynamically allocated memory associated with the multimap
 * data structure.
 */
void clear_multimap(multimap *mm) {
    assert(mm != NULL);
    free_multimap_node(mm, 0);
    mm->root = NULL;
    free(mm->root);
}


/* Adds the specified (key, value) pair to the multimap. */
void mm_add_value(multimap *mm, int key, int value) {
    multimap_node node;
    int arr_index;
    assert(mm != NULL);

    /* Look up the node with the specified key.  Create if not found. */
    arr_index = find_mm_node(mm, key, /* create */ 1);
    node = mm->root[arr_index];

    assert(node.key == key);
    
    /* Add the new value to the multimap node. */
    mm->root[arr_index].size++;
    mm->root[arr_index].values = (int*) realloc(node.values, mm->root[arr_index].size * sizeof(int));
    mm->root[arr_index].values[mm->root[arr_index].size - 1] = value;
}


/* Returns nonzero if the multimap contains the specified key-value, zero
 * otherwise.
 */
int mm_contains_key(multimap *mm, int key) {
    return find_mm_node(mm, key, /* create */ 0) != -1;
}


/* Returns nonzero if the multimap contains the specified (key, value) pair,
 * zero otherwise.
 */
int mm_contains_pair(multimap *mm, int key, int value) {
    multimap_node node;
    int *curr;
    int i;
    int arr_index;
    arr_index = find_mm_node(mm, key, /* create */ 0);
    node = mm->root[arr_index];
    if (arr_index == -1)
        return 0;
    curr = node.values;
    for (i = 0; i <= node.size; i++)
    {
        if (curr[i] == value)
        {
            return 1;
        }
    }

    return 0;
}


/* This helper function is used by mm_traverse() to traverse every pair within
 * the multimap.
 */
void mm_traverse_helper(multimap *mm, int node_index, void (*f)(int key, int value)) {
    int *curr;
    int i;
    multimap_node node;
    node = mm->root[node_index];
    if (node_index == -1)
        return;

    mm_traverse_helper(mm, node.left_child_index, f);
    int key = node.key;
    curr = node.values;
    for (i = 0; i < node.size; i++)
    {
        f(key,curr[i]);
    }
    mm_traverse_helper(mm, node.right_child_index, f);
}


/* Performs an in-order traversal of the multimap, passing each (key, value)
 * pair to the specified function.
 */
void mm_traverse(multimap *mm, void (*f)(int key, int value)) {
    mm_traverse_helper(mm, 0, f);
}

