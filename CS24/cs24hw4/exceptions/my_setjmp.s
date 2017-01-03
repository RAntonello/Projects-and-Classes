 .globl my_setjmp
 .globl my_longjmp

my_setjmp:

        # Save values to env.
        mov     4(%esp), %eax
        mov 	%esp, 4(%eax)   # Save stack pointer
        mov     %ebp, 8(%eax)   # Save base pointer
        mov     %esi, 12(%eax)  # Save other callee-save registers
        mov     %edi, 16(%eax)
        mov     %ebx, 20(%eax)
        mov 	(%esp), %edx    # Save return address
       	mov 	%edx, (%eax)
        mov     $0, %eax                  # setjmp will always return 0
        ret

my_longjmp:
	mov 4(%esp), %ecx # Load env into ecx
	mov 8(%esp), %eax # longjmp will return its second argument
	mov 4(%ecx), %esp  # Get stack pointer from env
	pop %edx			
	push (%ecx)			# Push return address onto the stack
	mov 8(%ecx), %ebp # Get base pointer from env
	mov 12(%ecx), %esi # Get other callee-save registers from env
	mov 16(%ecx), %edi
	mov 20(%ecx), %ebx 
	mov $1, %edx
	test %eax, %eax  # If 0, ret 1
	cmovz %edx, %eax
	ret
