/* Declare constants for the multiboot header  */
.set ALIGN,     1<<0                /* align loaded modules on page boundaries */
.set MEMINFO,   1<<1                /* provide the memory map */
.set FLAGS,     ALIGN | MEMINFO     /* this is the Multiboot 'flag' field */
.set MAGIC,     0x1BADB002          /* 'magic number' lets bootloader find the header */
.set CHECKSUM,  -(MAGIC + FLAGS)    /* checksum of above, to prove we are in multiboot */

/* 
Declare a multiboot header that marks the program as a kernel. 
These are magic values that are documented in the multiboot standard. 
The bootloader will search for this signature in the first 8 KiB of the kernel file, 
aligned at a 32-bit boundary. 
The signature is in its own section so the header can be forced to be within the 
first 8 KiB of kernel file.
*/
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

/* 
The multiboot standard does not define the value of the stack pointer register
(esp) and it is up to the kernel to provide a stack. 
This allocates room for a small stack by creating a symbol at the bottom of it, 
then allocating 16384 bytes for it, and finally creating a symbol at the top. 
The stack grows downwards on x86. 
The stack is in its own section so it can be marked nobits,
which means the kernel file is smaller because it does not contain unitialized stack. 
The stack on x86 must be 16-byte aligned according to the System V ABI standard 
and de-facto extensions. 
The compiler will assume the stack is properly aligned and 
failure to align the stack will result in undefined behavior.
*/
.section .bss
.align 16
stack_bottom:
.skip 16384     # 16 KiB
stack_top:


/*
The linker script specifies _start as the entry point to the kernel and 
the bootloader will jump to this position once the kernel has been loaded. 
It doesn't make sense to return from this function as the bootloader is gone.
*/
.section .text
.global _start
.type _start, @function
_start:
    /*
    The bootloader has loaded us into 32-bit protected mode on x86 machine. 
    Interrupts are disabled. Paging is disabled. 
    The processor state is as defined in the multiboot standard. 
    The kernel has full control of the CPU. 
    The kernel can only make use of hardware features
    and any code it provides as part of itself. 
    There's no printf function, unless the kernel provides its own <stdio.h> header and 
    a prinf implementation. 
    There are no security restrictions, no safeguards, no debugging mechaninsms,
    only what the kernel provides itself. 
    It has absolute and complete power over the machine.
    */

    /*
    To set up a stack, we set the esp register to point to the top of the
    stack (as it grows downwards on x86 systems). This is necessarily done
    in assembly as languages such as C cannot function without a stack.
    */
    mov $stack_top, %esp

    /*
    This is a good place to initialize crucial processor state before the
    high-level kernel is entered. 
    It's best to minimize the early environment where crucial features offline. 
    Note that the processor is not fully initialized yet: 
    features such as floating point instruction set extensions are not initialized yet.
    the GDT should be loaded here. Paging should be enabled here.
    C++ features such as global constructors and exceptions will require 
    runtime support to work as well.
    */

