all:
	mkdir -p build
	nasm -felf64 ./src/main.asm && ld main.o -o ./build/main
