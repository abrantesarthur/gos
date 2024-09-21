# BINARIES
BIN=$$HOME/opt/cross/bin
GCC=$(BIN)/x86_64-elf-gcc
LD=$(BIN)/x86_64-elf-ld
QEMU=qemu-system-x86_64


C_SOURCES = $(wildcard kernel/*.c drivers/*.c)
HEADERS = $(wildcard kernel/*.h drivers/*.h)
OBJ = ${C_SOURCES:.c=.o}

.PHONY: os-image clean run-qemu run run-file 
all: os-image run-qemu

# TODO: use -f elf64 when supporting 64-bit mode
kernel/kernel_prefix.o: kernel/kernel_prefix.asm 
	nasm -f elf32 $< -o $@

# compile c files into object files in an environment without a standard library
# TODO: remove -m32 option when  compiling for 64 bits.
%.o: %.c
	$(GCC) -m32 -ffreestanding -c $< -o $@

# TODO: remove -m elf_i386 option when compiling for 64 bits.
# kernel/kernel.bin: kernel/kernel_prefix.o ${OBJ} 
# 	$(LD) -m elf_i386 -o $@ -Ttext 0x1000 $^ --oformat binary
kernel/kernel.bin: kernel/kernel_prefix.o kernel/kernel.o
	$(LD) -m elf_i386 -o $@ -Ttext 0x1000 $^ --oformat binary

boot/boot_loader.bin: boot/boot_loader.asm 
	nasm -f bin -I boot/ $< -o $@

os-image: boot/boot_loader.bin kernel/kernel.bin
	cat $^ > $@

.PHONY:
clean:
	rm -f kernel/*.o drivers/*.o kernel/*.bin drivers/*.bin boot/*.bin os-image

# run the boot loader
# usage: 'make run-boot-loader'
# This only switches to 32-bit mode, but does not load the kernel into memory.
.PHONY: 
run-boot-loader: boot/boot_loader.bin
	$(QEMU) -machine pc -fda $<

# run the kernel (boot_loader + kernel)
# -boot a: boot from floppy disk image we created (i.e. os-image)
.PHONY:
run: clean os-image
	$(QEMU) -machine pc -fda os-image -boot a


# catch all rule: prevent errors when arguments don't match anything
%:
	@: