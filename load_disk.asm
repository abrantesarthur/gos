load_disk:
	pusha
; interrupt setup
	mov ah, 0x02		; read sectores
	mov dl, 0x80		; from first floppy disk
	mov dh,	0			; starting head
	mov ch,	0			; cylinder

	mov bx, 0			; ES:BX buffer address where to write data
	mov es, bx			
	mov bx, 0x7c00 + 512
	
	int 0x13			; issue read

	jc disk_error		; catch errors
	popa
	ret
	disk_error:
		mov bx, DISK_ERROR_MSG
		call printf
		jmp $

DISK_ERROR_MSG db "An error occured while reading disk", 0

; AH: return code
; AL: actual amount of sectors read

