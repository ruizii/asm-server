all:
	mkdir -p build
	nasm -felf64 ./src/main.asm && ld ./src/main.o -o ./build/asm-server
