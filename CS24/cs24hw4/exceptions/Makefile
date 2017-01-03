OBJS = c_except.o my_setjmp.o ptr_vector.o divider.o
OBJS2 = c_except.o my_setjmp.o ptr_vector.o test_setjmp.o

CC = gcc
CFLAGS=-g -Wall -Werror
ASFLAGS=-g

# Detect if the OS is 64 bits.  If so, request 32-bit builds.
LBITS := $(shell getconf LONG_BIT)
ifeq ($(LBITS),64)
  CFLAGS += -m32
  ASFLAGS += -32
endif


divider : $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

test_setjmp : $(OBJS2)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

ptr_vector.c : ptr_vector.h
c_except.c : c_except.h my_setjmp.h
divider.c : c_except.h my_setjmp.h
test_setjump.c : c_except.h my_setjmp.h

clean :
	rm -f *.o *~ divider divider.exe
	rm -f *.o *~ test_setjmp test_setjmp.exe
