;
;
; La funcion parse_filename extrae el método y el nombre del archivo
; solicitados por el cliente
;
;

default rel

global parse_filename

%define MAX_PATH 256

section .text
parse_filename:
    push rbp
    mov rbp, rsp

    xor rcx, rcx
    lea r8, [rdi]

;
; Extraer el nombre del método para implementar funcionalidad en el futuro
;
methodname_loop:
.loop:
    mov dl, byte [r8 + rcx]
    cmp dl, ' '
    je .exitloop
    mov byte [_methodname + rcx], dl
    inc rcx
    jmp .loop

.exitloop:
    mov byte [_methodname + rcx], 0
    mov [_methodname.len], rcx
    add r8, rcx
    inc r8

;
; Extraer el nombre del archivo y retornar un puntero a él
;
filename_loop:
    xor rcx, rcx

;
; Evita leer archivos desde la raiz del filesystem incrementando el puntero
; con el nombre del archivo hasta que deje de encontrar slashes
;
.remove_slash_loop:
    cmp byte [r8], '/'
    jne .validation
    inc r8
    jmp .remove_slash_loop

.validation:
.loop:
    mov dl, byte [r8 + rcx]        ; Siguiente caracter en dl

    cmp dl, ' '                    ; Si es un espacio, se llegó al final del nombre
    je .exitloop

    mov byte [_filename + rcx], dl ; Se guarda el caracter en _filename

    inc rcx
    cmp rcx, MAX_PATH              ; Si supera 256, se supera el limite de caracteres
    je invalid_path
    jmp .loop

.exitloop:
    mov byte [_filename + rcx], 0  ; Null terminator
    mov [_filename.len], rcx

exit_parse:
    lea rax, [_filename] ; Retorna un puntero al nombre del archivo
    leave
    ret

invalid_path:
    xor rax, rax ; Return NULL
    leave
    ret

section .bss
    _methodname: resb 128
    .len: resb 8

    _filename: resb MAX_PATH
    .len: resb 8
