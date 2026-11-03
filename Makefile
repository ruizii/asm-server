all: release

release:
	mkdir -p build
	nasm -felf64 ./src/main.asm && ld -s -z noseparate-code ./src/main.o -o ./build/asm-server

debug:
	mkdir -p build
	nasm -felf64 -g ./src/main.asm && ld ./src/main.o -o ./build/asm-server

clean:
	rm -f ./build/* ./src/*.o

.PHONY: all release debug clean
