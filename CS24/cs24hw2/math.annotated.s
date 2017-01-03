/* This file contains IA32 assembly-language implementations of three
 * basic, very common math operations.
 * The common theme of each of these implementations is that they all avoid
 * branching (for instance, branching based on the top bit of the operand), which 
 * is the way an individual might code these naively. This is done to save processor
 * time, as branching is computationally expensive compared to other operations.
 */

    .text

/*====================================================================
 * int f1(int x, int y) ## This function returns min of two ints.
 */
.globl f1 
f1:
	pushl	%ebp             ## Save frame pointer
	movl	%esp, %ebp  ## Set new base pointer
	movl	8(%ebp), %edx ## Load first argument into %edx
	movl	12(%ebp), %eax ## Load second argument into %eax
	cmpl	%edx, %eax ## Compare first and second argument 
	cmovg	%edx, %eax ## If %eax > %edx, move %edx to %eax
	popl	%ebp ## Replace from pointer
	ret


/*====================================================================
 * int f2(int x) ## Computes absolute value of x
 */
.globl f2
f2:
	pushl	%ebp         ## Save frame pointer
	movl	%esp, %ebp   ## Set new base pointer
	movl	8(%ebp), %eax ## Load first argument into %eax
	movl	%eax, %edx ## Copy first argument into %edx
	sarl	$31, %edx  ## Extend sign bit of edx 
	#(000..000 or 111..111 based on sign bit)
	xorl	%edx, %eax ## Set sign of eax to 0 if not already
	subl	%edx, %eax ## If first argument is positive, 
	                   ## do nothing, otherwise get two's complement
	popl	%ebp  ## Replace frame pointer
	ret


/*====================================================================
 * int f3(int x) ## Returns 1 if x is > 0, 0 if x is 0, -1 if x is < 0
 */
.globl f3
f3:
	pushl	%ebp  ## Save frame pointer
	movl	%esp, %ebp  ## Set new base pointer
	movl	8(%ebp), %edx ## Load first argument into %edx
	movl	%edx, %eax ## Copy first argument to %eax
	sarl	$31, %eax  ## Extend sign bit of eax
	                   ## (000..000 or 111..111 based on sign bit)
	testl	%edx, %edx ## Check to see if edx is > zero
	movl	$1, %edx ## Store 1 in edx
	cmovg	%edx, %eax ## If edx was > 0  in the check,
                       ## return 1, else return the extended
                       ## sign (either -1 or 0).
	popl	%ebp ## Replace frame pointer
	ret

s