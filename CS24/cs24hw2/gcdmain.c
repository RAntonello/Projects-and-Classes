#include <stdio.h>
#include <stdlib.h>

extern int recur_gcd(int a, int b); // Gcd definition in separate module
 
int main (int argc, char **argv) {
	if (argc != 3)
	{
		// Return error if there are an incorrect number of inputs
		fprintf(stderr, "Incorrect number of inputs\n"); 
		return 1;
	}
	if (atoi(argv[1]) < 1 || atoi(argv[2]) < 1)
	{
		// Return error if either argument is negative
		fprintf(stderr, "An argument is negative.\n"); 
		return 1;
	}
    int ret = recur_gcd(atoi(argv[1]),atoi(argv[2])); // Call assembly code for gcd
    printf("recur_gcd returned %d\n", ret); // return value
    return 0;
}
