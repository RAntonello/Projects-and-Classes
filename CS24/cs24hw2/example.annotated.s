	.file	"example.c"
	.text
	.p2align 4,,15
	.globl	ex
	.type	ex, @function
ex:
.LFB0:
	.cfi_startproc
	movl	8(%esp), %eax # eax = b
	subl	12(%esp), %eax # eax = b - c (subtraction) 
	imull	4(%esp), %eax  # eax = a * (b - c) (multiplication)
	addl	16(%esp), %eax # eax = a * (b - c) + d (addition)
	ret
	.cfi_endproc
.LFE0:
	.size	ex, .-ex
	.ident	"GCC: (Ubuntu 4.8.5-2ubuntu1~14.04.1) 4.8.5"
	.section	.note.GNU-stack,"",@progbits
 