; Add non-executable stack section
section .note.GNU-stack noalloc noexec nowrite progbits

; Common macros and definitions can go here
%define ALIGN_STACK rbp, rsp
