# BINARIES
BIN=$$HOME/opt/cross/bin
GCC=$(BIN)/x86_64-elf-gcc
LD=$(BIN)/x86_64-elf-ld


C_SOURCES = $(wildcard kernel/*.c drivers/*.c)
HEADERS = $(wildcard kernel/*.h drivers/*.h)
OBJ = ${C_SOURCES:.c=.o}

.PHONY: os-image clean run-qemu run run-file 
all: os-image run-qemu

kernel/kernel_prefix.o: kernel/kernel_prefix.asm 
	nasm -f elf64 $< -o $@

# compile c files into object files in an environment without a standard library
%.o: %.c
	$(GCC) -ffreestanding -c $< -o $@

kernel/kernel.bin: kernel/kernel_prefix.o ${OBJ} 
	$(LD) -o $@ -Ttext 0x1000 $^ --oformat binary

boot/boot_loader.bin: boot/boot_loader.asm 
	nasm -f bin $< -o $@

os-image: boot/boot_loader.bin kernel/kernel.bin
	cat $^ > $@

clean: ${wildcard *.o *.bin}
	rm kernel/*.o drivers/*.o kernel/*.bin drivers/*.bin boot/*.bin os-image

run-qemu: os-image
	qemu-system-x86_64 -machine pc os-image

.PHONY: 
run: boot/boot_loader.bin 
	qemu-system-x86_64 boot/boot_loader.bin

.PHONY:
run-file: nasm
	nasm -f bin $(f).asm -o $(f).bin && \
	qemu-system-x86_64 $(f).bin