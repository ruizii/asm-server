default rel

global parse_filename

section .text
parse_filename:
    push rbp
    mov rbp, rsp

    xor rcx, rcx

    lea r8, [rdi]

methodname_loop:
.loop:
    mov dl, byte [r8 + rcx]
    cmp dl, 0x20 ; espacio
    je .exitloop
    mov byte [method + rcx], dl
    inc rcx
    jmp .loop

.exitloop:
    inc rcx
    mov byte [method+rcx], 0
    mov [method.len], rcx
    add r8, rcx
    inc r8

    cmp byte [r8], 0x20
    je exit_parse

filename_loop:
    xor rcx, rcx

.loop:
    mov dl, byte [r8 + rcx]
    cmp dl, 0x20 ; espacio
    je .exitloop
    mov byte [filename + rcx], dl
    inc rcx
    jmp .loop

.exitloop:
    inc rcx
    mov byte [filename+rcx], 0
    mov [filename.len], rcx
    lea rax, [filename]

exit_parse:
    leave
    ret

section .bss
    method: resb 128
    .len: resb 8

    filename: resb 256
    .len: resb 8
