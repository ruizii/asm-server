default rel

%define AF_INET 2
%define ACCEPT 43
%define SOCK_STREAM 1
%define SOCKET 41
%define STDOUT 1
%define BIND 49
%define LISTEN 50
%define READ 0
%define WRITE 1

global _start

section .text
_start:
    push rbp
    mov rbp, rsp
    sub rsp, 16

socket:
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    mov rax, SOCKET
    syscall ; rax tiene el socket

    cmp rax, 0
    jb .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [sock_error_msg]
    mov rdx, sock_error_msg_len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:
    mov dword [s], eax

    ; Mover bytes en network order
    mov bx, 8000
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
    mov rdx, bind_error_msg_len
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
    mov rdx, listen_error_msg_len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

write1:
    mov rdi, STDOUT
    lea rsi, [listen_msg]
    mov rdx, listen_msg_len
    mov rax, WRITE
    syscall

    cmp rax, -1
    je .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [write_error_msg]
    mov rdx, write_error_msg_len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

accept:
    mov rdi, [s]
    mov rsi, 0
    mov rdx, 0
    mov rax, ACCEPT
    syscall
    cmp rax, 0

    mov [client_fd], eax

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
    mov rdx, read_error_msg_len
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
    mov rdx, write_error_msg_len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:

write3:
    mov rdi, [client_fd]
    lea rsi, [RES_200_OK]
    mov rdx, RES_200_OK_LEN
    mov rax, WRITE
    syscall

    cmp rax, -1
    je .error
    jmp .continue

.error:
    mov rdi, STDOUT
    lea rsi, [write_error_msg]
    mov rdx, write_error_msg_len
    mov rax, WRITE
    syscall

    jmp exit_err

.continue:
    mov rdi, [client_fd]
    mov rax, 3
    syscall

    mov rdi, [s]
    mov rax, 3
    syscall

    leave
    mov rdi, 1
    mov rax, 60
    syscall

exit_err:
    leave
    mov rdi, 1
    mov rax, 60
    syscall

section .data
    BUFFER_SIZE: equ 1024

    listen_msg: db `Escuchando en 0.0.0.0:8000\n\n`
    listen_msg_len: equ $ - listen_msg

    sock_error_msg: db `Error: socket\n`
    sock_error_msg_len: equ $ - sock_error_msg

    bind_error_msg: db `Error: bind\n`
    bind_error_msg_len: equ $ - bind_error_msg

    listen_error_msg: db `Error: listen\n`
    listen_error_msg_len: equ $ - listen_error_msg

    write_error_msg: db `Error: write\n`
    write_error_msg_len: equ $ - write_error_msg

    read_error_msg: db `Error: read\n`
    read_error_msg_len: equ $ - read_error_msg

    RES_200_OK: db `HTTP/1.1 200 OK\r\nServer: asm\r\n\r\n`
    RES_200_OK_LEN: equ $ - RES_200_OK

section .bss
    s: resb 4
    client_fd: resb 4
    buffer: resb 1024
    file_buffer: resb 4096
    filename: resb 256
