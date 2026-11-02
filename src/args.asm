%define MAX_PORT 65535

section .text
parse_args:
    push rbp
    mov rbp, rsp
    push rbx

    lea rbx, [rdi + 8] ; Salta argv[0]

.loop:
    mov rsi, [rbx]
    test rsi, rsi
    jz .done

    cmp byte [rsi], '-'
    jne usage_error
    cmp byte [rsi + 1], 0
    je usage_error
    cmp byte [rsi + 2], 0
    jne usage_error

    mov dl, [rsi + 1]
    cmp dl, 'd'
    je .dir
    cmp dl, 'p'
    je .port
    cmp dl, 'h'
    je usage
    jmp usage_error

.dir:
    add rbx, 8 ; Valor en el siguiente argumento
    mov rsi, [rbx]
    test rsi, rsi
    jz usage_error

    mov [dir], rsi
    add rbx, 8
    jmp .loop

.port:
    add rbx, 8
    mov rsi, [rbx]
    test rsi, rsi
    jz usage_error

    mov [port_str], rsi
    call parse_port
    test rax, rax
    js port_error

    mov [port], ax
    add rbx, 8
    jmp .loop

.done:
    pop rbx
    leave
    ret

parse_port:
    xor rax, rax
    xor rcx, rcx

    cmp byte [rsi], 0
    je .invalid

.loop:
    movzx edx, byte [rsi + rcx]
    test dl, dl
    jz .exitloop

    sub dl, '0'
    cmp dl, 9
    ja .invalid

    imul rax, rax, 10
    add rax, rdx
    cmp rax, MAX_PORT
    ja .invalid

    inc rcx
    jmp .loop

.exitloop:
    test rax, rax
    jz .invalid
    ret

.invalid:
    mov rax, -1
    ret

strlen:
    xor rax, rax

.loop:
    cmp byte [rdi + rax], 0
    je .exitloop
    inc rax
    jmp .loop

.exitloop:
    ret

usage:
    mov rdi, STDOUT
    lea rsi, [usage_msg]
    mov rdx, usage_msg.len
    mov rax, WRITE
    syscall

    mov rdi, 0
    mov rax, EXIT
    syscall

usage_error:
    mov rdi, STDOUT
    lea rsi, [usage_msg]
    mov rdx, usage_msg.len
    mov rax, WRITE
    syscall

    mov rdi, 1
    mov rax, EXIT
    syscall

port_error:
    mov rdi, STDOUT
    lea rsi, [port_error_msg]
    mov rdx, port_error_msg.len
    mov rax, WRITE
    syscall

    mov rdi, 1
    mov rax, EXIT
    syscall

section .data
    usage_msg: db BLUE, "Usage:", MAGENTA, " asm-server ",RESET, "[", CYAN, "-d", YELLOW, " DIR", RESET, "] [",CYAN, "-p", YELLOW, " PORT", RESET, "]", 0x0a, 0x0a
               db CYAN, "  -d ", YELLOW, "DIR   ", RESET, "serve files from DIR (default:", YELLOW, " current directory", RESET, ")", 0x0a
               db CYAN, "  -p ", YELLOW, "PORT  ", RESET,  "listen on PORT, 1-65535 (default:", YELLOW, " 8000", RESET, ")", 0x0a
               db CYAN, "  -h       ", RESET, "show this help", 0x0a
    .len: equ $ - usage_msg

    port_error_msg: db "Error: invalid port, must be between 1 and 65535", 0x0a
    .len: equ $ - port_error_msg

    default_port_str: db "8000", 0

    port: dw 8000
    port_str: dq default_port_str

section .bss
    dir: resq 1
