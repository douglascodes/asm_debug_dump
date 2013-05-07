test_debug: test_debug.o debug_dump.o
	ld -o test_debug test_debug.o debug_dump.o

debug_dump.o: debug_dump.asm
	nasm -o debug_dump.o debug_dump.asm

test_debug.o: test_debug.asm
	nasm -o test_debug.o test_debug.asm
