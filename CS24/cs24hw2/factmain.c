#include <stdio.h>
#include <stdlib.h>

extern int fact(int a); // Fact definition in separate module
 
int main (int argc, char **argv) {
	if (argc > 2)
	{
		// Return error if there is more thatn 1 input
		fprintf(stderr, "More than 1 input\n"); 
		return 1;
	}
	if (atoi(argv[1]) < 0)
	{
		// Return error if argument is negative
		fprintf(stderr, "Argument is negative.\n"); 
		return 1;
	}
    int ret = fact(atoi(argv[1])); // Call assembly
    printf("fact returned %d\n", ret); // return value
    return 0;
}
