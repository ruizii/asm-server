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
    mov byte [method + rcx], 0
    mov [method.len], rcx
    add r8, rcx
    inc r8

filename_loop:
    xor rcx, rcx

remove_slash:
    cmp byte [r8], '/'
    jne .loop
    inc r8
    jmp remove_slash

.loop:
    mov dl, byte [r8 + rcx]
    cmp dl, 0x20 ; espacio
    je .exitloop
    mov byte [_filename + rcx], dl
    inc rcx
    jmp .loop

.exitloop:
    mov byte [_filename + rcx], 0
    mov [_filename.len], rcx

exit_parse:
    lea rax, [_filename]
    leave
    ret

section .bss
    method: resb 128
    .len: resb 8

    _filename: resb 256
    .len: resb 8
