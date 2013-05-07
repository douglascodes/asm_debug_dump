%include "popemall.mac" ; Simple macros for pushing /popping all regs.

%macro Save_Regs 0
    push rax                ; Save for later
    push rbx                ; Save for later
    push rcx                ; Save for later
    push rdx                ; Save for later
    push r15                ; Save for later
%endmacro

%macro Restore_regs 0
    pop r15                 ; Get back original values
    pop rdx                 ; Get back original values
    pop rcx                 ; Get back original values
    pop rbx                 ; Get back original values
    pop rax                 ; Get back original values
%endmacro

%macro Write_register_x 2   ; $1 = Four byte string. Ex. 'RCX:' $2 = reg64
    Save_Regs
    call Flip_EOL
    mov eax, %1                 ; Loads EAX with string
    mov [RAX_message], eax      ; Moves string to memory location for the name

    mov rax, %2                 ; Moves actual register into RAX
    call Cycle_each_register    ; Calls the Register print cycle.
    Restore_regs
%endmacro

%macro Write_eflags_reg 0
  Save_Regs
  pushf
  pushf
  pop rax
  mov rcx,22
  mov rdx,Flag_bits

Cycle_flag_bits:
  shr rax, 1
  jnc Leave_flag
  mov [rdx+rcx], byte '*'

Leave_flag:
  sub rcx, 1
  cmp rcx, 0
  jne Cycle_flag_bits

  call Write_flag_message
  popf
  Restore_regs
%endmacro
; An attempt to load a quick-use debug script
; for printing the register values, and stack values.
; Basically just loads the variables into preset text fields and sends to
; std_out

SECTION .data           ; Section containing initialised data
    Reg_msg_len:    equ Reg_List - RAX_message
    Mem_msg_len:    equ Reg_List - Memory_message
    Reg_txt_len:    equ 4
    Memory_message: db "0000:"
    RAX_message:    db "nnn: "
    RAX_Value:      db "xxxx.0000.0000.0000h"
    EOL_toggle:     db 10
    Reg_List:       db ""
    Flag_bits:      db 10,'                      ',10
    FLAGS_Mask:     db 'IVVAVR NiiODITSZ A P C',10
                    db 'DPFCMF T10FFFFFF F F F',10
    Flag_msg_len:   equ $-Flag_bits

SECTION .text           ; Section containing code
global _DEBUG_Register_Dump

_DEBUG_Register_Dump:
    pushemall
    Write_eflags_reg
    Write_register_x "RAX:",rax
    Write_register_x "RBX:",rbx
    Write_register_x "RCX:",rcx
    Write_register_x "RDX:",rdx
    Write_register_x "RDI:",rdi
    Write_register_x "RSI:",rsi
    Write_register_x "RBP:",RBP
    Write_register_x "RSP:",RSP
    Write_register_x "R8 :",R8
    Write_register_x "R9 :",R9
    Write_register_x "R10:",R10
    Write_register_x "R11:",R11
    Write_register_x "R12:",R12
    Write_register_x "R13:",R13
    Write_register_x "R14:",R14
    Write_register_x "R15:",R15

    jmp End_Proc            ; Goes to return procedure

; Saves register


Cycle_each_register:
    Save_Regs
    push rax                ; Save for later
    call Rewrite_Value      ; Zeroes out the ASCII number value
    pop rax                 ; Use now

    call Print_into_memory_string   ; Calls the debug routine to put chars into Memory for printing
    call Write_reg_message          ; Writes the value of N-register in the text to std_out

    Restore_regs
    ret

; Flip End of Line
Flip_EOL:
    mov al, [EOL_toggle]
    cmp al, 10
    je Make_Tab
    add al, 2
Make_Tab:
    dec al
    mov [EOL_toggle], al
    ret


Write_flag_message:
    mov rcx,Flag_bits          ; Pass offset of the message
    mov rdx,Flag_msg_len        ; Pass the length of the message
    jmp Write_Msg

Write_reg_message:
    mov rcx,RAX_message         ; Pass offset of the message
    mov rdx,Reg_msg_len         ; Pass the length of the message
    jmp Write_Msg

Write_mem_message:
    mov rcx,Memory_message      ; Pass offset of the message
    mov rdx,Mem_msg_len         ; Pass the length of the message

; Write msg sends to std_out the passed
; String_offset:RCX
; String_length:RDX
Write_Msg:
    mov rax,4               ; Specify sys_write call
    mov rbx,1               ; Specify File Descriptor 1: Standard Output
    int 80H                 ; Make kernel call
    ret

; Takes RAX and prints the char representation of it into the specified memory address at :RAX_Value
Print_into_memory_string:
    mov rdx, RAX_Value+3
    mov rcx, 15              ; Count for each nibble of 64 bit Register RAX
    mov rbx, 15             ; AND mask for the first 4 bits.
    mov r15, rax            ; Copies the value from RAX to r15, since this prints RAX's value

Conversion_loop:
    mov rax, rbx            ; Copy this to RAX for quick resetting
    and rax, r15            ; Keeps only the matching bits in nibble.
    cmp al, 9               ; Compare al to 9 for 0-9 digits
    jna Digit_Only          ; No need to compensate for A-F

    add al, 'A'-'9'-1         ; put the difference between these chars into al

Digit_Only:
    add [rdx+rcx], al       ; Adds the "value" of nibble to char '0'
    mov rax, rcx            ; Readies to check if rcx is divisible by 4

    shr rax, 1              ; Binary ones column into carry flag. (Odd number)
    jc Dont_Add_space       ; Jump past the rdx dec
    shr rax, 1              ; Binary twos column into carry flag. (Even number)
    jc Dont_Add_space       ; Jump past the rdx dec

    dec rdx                 ; The number is even, so decrement rdx to adjust for spacers

Dont_Add_space:

    ror r15, 4              ; We rotate the lowest four bits for comparison against AL's mask
    dec rcx                 ; Adjusts the counter/pointer by one hex place
    cmp rcx, 0h             ; We want to keep rcx if zero
    jnl Conversion_loop
    ret                     ; Returns after completing the registers full value

Rewrite_Value:
    mov eax, '0000'
    mov [RAX_Value], eax
    mov [RAX_Value+5], eax
    mov [RAX_Value+10], eax
    mov [RAX_Value+15], eax
    ret

End_Proc:
    mov [EOL_toggle], byte 10
    mov rax,4               ; Specify sys_write call
    mov rbx,1               ; Specify File Descriptor 1: Standard Output
    mov rcx,EOL_toggle      ; Pass offset of the message
    mov rdx,1               ; Pass the length of the message
    int 80H                 ; Make kernel call

    popemall
    ret                     ; Go back to calling module

SECTION .bss            ; Section containing uninitialized data
