#
# Commands and arguments
#
CC = gcc
RM = rm

# ADD -m32 ON 64BIT PLATFORMS
CFLAGS = -Wall -g -std=c99 -pedantic -m32

# ADD -32 ON 64BIT PLATFORMS
ASFLAGS = -g -32


all: test test_arg test_ret

# Test that threads return correctly
test_ret: sthread.o glue.o test_ret.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

# Test that arguments are passed correctly
test_arg: sthread.o glue.o test_arg.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

# The simple test program
test: sthread.o glue.o test.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^


# pseudo-target to clean up
clean:
	$(RM) -f *.o core* *~ test


.PHONY: all clean


# Dependencies
sthread.c: sthread.h
test.c: sthread.h

