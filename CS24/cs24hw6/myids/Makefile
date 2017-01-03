CC = gcc
CFLAGS = -Wall -Werror -m32
ASFLAGS = -g -32

# Detect if the OS is 64 bits.  If so, request 32-bit builds.

OBJS = myids.o get_ids.o
EXEC = myids


all: $(EXEC)

$(EXEC): $(OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f *~ *.o $(EXEC) $(EXEC).exe

.PHONY:  clean all

