all:
	nasm -felf64 main.asm && ld main.o -o main
