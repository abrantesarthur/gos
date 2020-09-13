boot_sector.bin: boot_sector.asm printf.asm load_disk.asm printh.asm
	nasm -f bin boot_sector.asm -o boot_sector.bin

test_load_disk.bin: printf.asm printh.asm load_disk.asm
	nasm -f bin test_load_disk.asm -o test_load_disk.bin

.PHONY: run
run: boot_sector.bin 
	qemu-system-x86_64 boot_sector.bin
	
.PHONY: test_load_disk
test_load_disk: test_load_disk.bin
	qemu-system-x86_64 test_load_disk.bin
