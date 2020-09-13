[org 0x7c00]
[bits 16]

; ---------------------------------------------------
; BOOT_SECTOR: the first 512 bytes are read into
; ---------------------------------------------------
section .text				; entrypoints
	global main


main:

cli							; clear interrupts
jmp 0x0000:ZeroSeg
ZeroSeg:					; clear segment registers
	xor ax, ax
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov sp, main
	cld						; clear direction flag
sti							; reinstate interrupts


push ax
xor ax, ax					; reset disk
mov dl, 0x80
int 0x13
pop ax

jmp $

%include "printh.asm"
%include "printf.asm"
%include "load_disk.asm"

times 510-($-$$) db 0
dw 0xaa55

