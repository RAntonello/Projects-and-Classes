.globl get_ids

# get_ids:
# Arguments are int pointers to uid and gid.
# get_ids stores the user id and group id in the memory
# locations referenced by these pointers.


get_ids:
    
    # Set up stack frame.
    push %ebp
    mov  %esp, %ebp

    # Save callee register
    push %ebx

    mov     8(%ebp), %ebx  # Load uid pointer into %ebx
    mov    12(%ebp), %ecx # Load gid pointer into %ecx

    movl $199, %eax
    int $0x80         # Get uid
    mov %eax, (%ebx) # Store it in (%ebx)
    mov $200, %eax
    int $0x80        # Get gid
    mov %eax, (%ecx)  # Store it in (%ecx)

    # Restore callee-save register.
    pop %ebx

    # Clean up stack
    mov %ebp, %esp
    pop %ebp

    ret

