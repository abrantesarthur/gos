main.bin: main.asm printf.asm load_disk.asm
	nasm -f bin main.asm -o main.bin

.PHONY: run
run: main.bin 
	qemu-system-x86_64 main.bin

.PHONY: clean
clean:
	if [rm main.bin
