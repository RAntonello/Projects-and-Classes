#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "c_except.h"
#include "my_setjmp.h"
#include "ptr_vector.h"

void test1();
void test2();
void test3();
void test4();



int main(int argc, char const *argv[])
{
	test1();
	test2();
	test3();
	test4();
	return 0;
}

void test1()
{
    // Test for correct setjmp return
	jmp_buf env;
    int exception = setjmp(env);
    if (exception == 0)
    {
    	printf("TEST 1: setjmp(buf) returns 0: PASS\n");
    }
    else
    {
    	printf("TEST 1: setjmp(buf) returns %d, not 0: FAIL", exception);
    }
}

void test2()
{
    // Test that longjmp returns 1 when 2nd arg is 0
	jmp_buf env;
	int count = 0;
    int exception = setjmp(env);
    if (exception == 1)
    {
    	printf("TEST 2: longjmp(env, 0) returns 1: PASS\n");
    }
    else
    {
    	if (count == 0)
    	{
    		count++;
    		longjmp(env, 0);
    	}
    	printf("TEST 2: longjmp(env, 0) returns %d, not 1: FAIL", exception);
    }
}

void test3()
{
    // Test that longjmp returns 2nd arg when 2nd arg is nonzero
	jmp_buf env;
	int count = 0;
    int exception = setjmp(env);
    if (exception == 42)
    {
    	printf("TEST 3: longjmp(env, 42) returns 42: PASS\n");
    }
    else
    {
    	if (count == 0)
    	{
    		count++;
    		longjmp(env, 42);
    	}

    	printf("TEST 3: longjmp(env, 42) returns %d, not 42: FAIL", exception);
    }
}

void test4()
{
    // Test that setjmp does not modify values to its right
    jmp_buf env;
    int exception = setjmp(env);
    int *new_p;
    new_p =  (int *) (void *) (env + 1);
    *new_p = 5;
    int count = 0;
    if (*new_p == 5 && exception == 0)
    {
        printf("TEST 4: setjmp does not modify values to its right: PASS\n");
    }
    else
    {
        if (count == 0)
        {
            count++;
            longjmp(env, 42);
        }
        printf("TEST 4: setjmp does not modify values to its right: FAIL\n");
    }
}
