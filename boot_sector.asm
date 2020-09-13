; ---------------------------------------------------
; BOOT_SECTOR:	this first 512 bytes are read into memory by the BIOS routine.
;				it switches the CPU to 32-bit protected mode
; ---------------------------------------------------
[org 0x7c00]				; tell the assembler the address where BIOS
							; loads the boot sector

mov bp, 0x9000				; set the stack
mov sp, bp

mov si, MSG_REAL_MODE
call printf

call switch_to_pm			; we never return from here

jmp $

%include "printf.asm"
%include "global_descriptor_table.asm"
%include "printf_pm.asm"
%include "switch_to_pm.asm"

[bits 32]

; This is where we arrive after switching to and initializing protected mode
BEGIN_PM:
	mov ebx, MSG_PROT_MODE
	call printf_pm

	jmp $					; hang

; Global variables
MSG_REAL_MODE db "Started in 16-bit real mode", 0
MSG_PROT_MODE db "Succesfully landed in 32-bit protected mode", 0

; Bootsector padding
times 510-($-$$) db 0
dw 0xaa55

