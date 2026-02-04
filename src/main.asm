default rel

%include "./src/parse.asm"

; Syscalls
%define ACCEPT 43
%define FORK 57
%define SOCKET 41
%define SETSOCKOPT 54
%define BIND 49
%define EXIT 60
%define LISTEN 50
%define READ 0
%define WRITE 1
%define OPEN 2
%define CLOSE 3

; Consts
%define SOL_SOCKET 1
%define SO_REUSEADDR 2
%define AF_INET 2
%define SOCK_STREAM 1
%define STDOUT 1
%define BUFFER_SIZE 1024
%define FILE_BUFFER_SIZE 8192
%define O_RDONLY 0

; Colors
%define RED     `\x1b[31m`;
%define GREEN   `\x1b[32m`;
%define YELLOW  `\x1b[33m`;
%define BLUE    `\x1b[34m`;
%define MAGENTA `\x1b[35m`;
%define CYAN    `\x1b[36m`;
%define RESET   `\x1b[0m`;


global _start

section .text
_start:
    push rbp
    mov rbp, rsp
    sub rsp, 32

socket:
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    mov rax, SOCKET
    syscall ; rax tiene el socket

    cmp rax, 0
    jl .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [sock_error_msg]
    mov rdx, sock_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:
    mov dword [s], eax

    mov rdi, [s]             ; socket file descriptor
    mov rsi, SOL_SOCKET      ; level
    mov rdx, SO_REUSEADDR    ; optname
    mov r10, so_reuseaddr
    mov r8 , so_reuseaddr.length
    mov rax, SETSOCKOPT
    syscall


    ; Mover bytes en network order
    mov bx, 80
    mov ah, bl
    mov al, bh

    ; struct sockaddr_in
    mov word [rsp], AF_INET  ; sin_family
    mov word [rsp+2], ax     ; sin_port
    mov dword [rsp+4], 0     ; sin_addr
    mov qword [rsp+8], 0     ; padding

bind:
    mov rdi, [s]             ; Socket de servidor
    lea rsi, [rsp]           ; struct sockaddr_in definido antes
    mov rdx, 16              ; Tamaño del struct
    mov rax, BIND
    syscall

    cmp rax, 0
    jne .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [bind_error_msg]
    mov rdx, bind_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

listen:
    mov rdi, [s]
    mov rsi, 10
    mov rax, LISTEN
    syscall

    cmp rax, 0
    jne .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [listen_error_msg]
    mov rdx, listen_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

write1:
    mov rdi, STDOUT
    lea rsi, [listen_msg]
    mov rdx, listen_msg.len
    mov rax, WRITE
    syscall

    cmp rax, -1
    je .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [write_error_msg]
    mov rdx, write_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

mainloop:
accept:
    mov rdi, [s]
    mov rsi, 0
    mov rdx, 0
    mov rax, ACCEPT
    syscall
    cmp rax, 0

    mov [client_fd], eax

    mov rax, FORK
    syscall

    cmp rax, 0
    je child

    mov rdi, [client_fd]

    mov rax, CLOSE
    syscall
    jmp mainloop

child:
    mov rdi, [s]
    mov rax, CLOSE
    syscall

read:
    mov rdi, [client_fd]
    lea rsi, [buffer]
    mov rdx, BUFFER_SIZE
    mov rax, READ
    syscall

    cmp rax, -1
    je .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [read_error_msg]
    mov rdx, read_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

write2:
    mov rdi, STDOUT
    lea rsi, [buffer]
    mov rdx, rax
    mov rax, WRITE
    syscall

    cmp rax, -1
    je .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [write_error_msg]
    mov rdx, write_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

parse:
    lea rdi, [buffer]
    call parse_filename ; Nombre del archivo en rax

    cmp rax, 0          ; Si hubo un error en el parseo
    je invalid_file_parsed
    cmp rax, -1         ; Si el cliente solicitó la raíz
    jne open_file
    lea rax, [index]

open_file:
    lea rdi, [rax]
    mov rsi, O_RDONLY
    mov rax, OPEN
    syscall

    cmp eax, -1
    jl not_found

    mov [file_fd], rax

write3:
    mov rdi, [client_fd]
    lea rsi, [RES_200_OK]
    mov rdx, RES_200_OK.len
    mov rax, WRITE
    syscall

    cmp rax, -1
    je .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [write_error_msg]
    mov rdx, write_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

; Lee los contenidos del archivo y los pone en el buffer [file_buffer]
;
;     -    Si la syscall retorna -1, hubo un error con read
;     -    Si la syscall retorn 0, se terminó de leer el contenido del archivo
;     -    Si retorna cualquier otro valor, se leyó contenido y la cantidad de bytes
;          se guarda en [content_length]
;
read_write_loop:
.read_file:
    mov rdi, [file_fd]
    lea rsi, [file_buffer]
    mov rdx, FILE_BUFFER_SIZE
    mov rax, READ
    syscall

    cmp rax, -1
    je .read_file_error
    cmp rax, 0
    je .continue

    mov [content_length], rax

.write_file_contents:
    mov rdi, [client_fd]
    lea rsi, [file_buffer]
    mov rdx, [content_length]
    mov rax, WRITE
    syscall

    cmp rax, -1
    je .write_file_error
    jmp .read_file

; Errores
.read_file_error:
    mov rdi, STDOUT
    lea rsi, [read_error_msg]
    mov rdx, read_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.write_file_error:
    mov rdi, STDOUT
    lea rsi, [write_error_msg]
    mov rdx, write_error_msg.len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

exit:
    mov rdi, [file_fd]
    mov rax, CLOSE
    syscall

    mov rdi, [client_fd]
    mov rax, CLOSE
    syscall

    leave
    mov rdi, 0
    mov rax, EXIT
    syscall

exit_err:
    leave
    mov rdi, 1
    mov rax, EXIT
    syscall

not_found:
    mov rdi, [client_fd]
    lea rsi, [RES_404_NOT_FOUND]
    mov rdx, RES_404_NOT_FOUND.len
    mov rax, WRITE
    syscall

    mov rdi, [client_fd]
    mov rax, CLOSE
    syscall

    leave
    mov rdi, 0
    mov rax, EXIT
    syscall

invalid_file_parsed:
    mov rdi, [client_fd]
    lea rsi, [RES_400_BAD_REQUEST]
    mov rdx, RES_400_BAD_REQUEST.len
    mov rax, WRITE
    syscall

    mov rdi, [client_fd]
    mov rax, CLOSE
    syscall

    leave
    mov rdi, 0
    mov rax, EXIT
    syscall


section .data
    listen_msg: db "[", BLUE, "+", RESET, "] ", "Listening on: ", BLUE, "0.0.0.0", RESET, ":", BLUE, "80", RESET, 0x0a, 0x0a
    .len: equ $ - listen_msg

    sock_error_msg: db "Error: socket", 0x0a
    .len: equ $ - sock_error_msg

    bind_error_msg: db "Error: bind", 0x0a
    .len: equ $ - bind_error_msg

    listen_error_msg: db "Error: listen", 0x0a
    .len: equ $ - listen_error_msg

    write_error_msg: db "Error: write", 0x0a
    .len: equ $ - write_error_msg

    read_error_msg: db "Error: read", 0x0a
    .len: equ $ - read_error_msg

    RES_200_OK: db "HTTP/1.1 200 OK", 0x0d, 0x0a, "Server: asm", 0x0d, 0x0a, 0x0d, 0x0a
    .len: equ $ - RES_200_OK

    RES_404_NOT_FOUND: db "HTTP/1.1 404 Not found", 0x0d, 0x0a, "Server: asm", 0x0d, 0x0a, 0x0d, 0x0a
    .len: equ $ - RES_404_NOT_FOUND

    RES_400_BAD_REQUEST: db "HTTP/1.1 400 Bad request", 0x0d, 0x0a, "Server: asm", 0x0d, 0x0a, 0x0d, 0x0a
    .len: equ $ - RES_400_BAD_REQUEST

    index: db "index.html", 0x00

    so_reuseaddr: dd 1
    .length: equ $ - so_reuseaddr


section .bss
    file_fd: resb 4
    s: resb 4
    client_fd: resb 4

    buffer: resb 1024
    file_buffer: resb FILE_BUFFER_SIZE
    content_length: resb 4
