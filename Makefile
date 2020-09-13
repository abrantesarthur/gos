main.bin: main.asm printf.asm load_disk.asm printh.asm
	nasm -f bin main.asm -o main.bin

test_load_disk.bin: printf.asm printh.asm load_disk.asm
	nasm -f bin test_load_disk.asm -o test_load_disk.bin

.PHONY: run
run: main.bin 
	qemu-system-x86_64 main.bin
	
.PHONY: test_load_disk
test_load_disk: test_load_disk.bin
	qemu-system-x86_64 test_load_disk.bin

.PHONY: clean
clean:
	if [rm main.bin
