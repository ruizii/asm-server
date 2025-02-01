default rel

global parse_filename

section .text
parse_filename:
    push rbp
    mov rbp, rsp

    lea r8, [rdi]

.loop:
    xor rcx, rcx

    mov dl, byte [r8 + rcx]
    cmp dl, 0x20 ; espacio
    je .exitloop
    mov byte [filename + rcx], dl
    inc rcx

.exitloop:
    lea rax, [filename]
    leave
    ret


section .bss

filename: resb 256
