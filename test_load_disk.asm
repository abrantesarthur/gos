[org 0x7c00]

mov bp, 0x8000
mov sp, bp

mov bx, 0x9000				; read disk to ES:BX = 0000:9000 memory address
mov al, 2 					; read 1 sector
call load_disk

mov dx, [0x9000]			; print hex value copied to memory
call printh


mov dx, [0x9000 + 512]
call printh

jmp $

%include "printh.asm" 
%include "printf.asm"
%include "load_disk.asm"

BOOT_DRIVE: db 0

times 510-($-$$) db 0
dw 0xaa55

times 256 dw 0xbada
times 256 dw 0xface
