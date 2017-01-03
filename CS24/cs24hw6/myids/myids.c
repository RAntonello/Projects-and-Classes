#include <stdio.h>
#include <stdlib.h>

extern void get_ids(int *uid, int *gid); // definition in get_ids.s
 
int main () {

    int uid, gid;
    get_ids(&uid, &gid);
    printf("User ID is %d. Group ID is %d.\n", uid, gid);
    return 0;
}
