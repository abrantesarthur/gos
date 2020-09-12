; BOOT_SECTOR: the first 512 bytes are read into
; memory by the boot loader

[org 0x7c00]

mov al, 1					; amount of sectors to read
mov cl, 2					; start reading from second sector
call load_disk				; read disk 
jmp second_sector			; executes code read from second sector

%include "printf.asm"
%include "load_disk.asm"

times 510-($-$$) db 0
dw 0xaa55

; _________________________________________________
; SECOND SECTOR: read by load_disk routine 
; _________________________________________________

second_sector:
	mov bx, TEST_STR
	call printf
	jmp $
	TEST_STR db "Reading From disk Worked!", 0
	times 509 db 0

