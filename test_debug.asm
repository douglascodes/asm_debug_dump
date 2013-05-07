; Just a wrapper to ensure debug.o is producing correctly
SECTION .data           ; Section containing initialised data

SECTION .text           ; Section containing code
    GLOBAL _start
    EXTERN _DEBUG_Register_Dump

_start:
    nop
    call _DEBUG_Register_Dump
    nop

NormalExit:     ; Jmp location for normal exit
    mov rbx,0   ; Move exit code of zero to bx
Exit:
    mov rax,1   ; Exit sys_call
    int 80h     ; Call kernel

SECTION .bss

