; load AL sectors to ES:BX from first floppy disk
load_disk:
	pusha
						; interrupt setup
	mov ah, 0x02		; read sectors mode
	mov dl, 0x80		; from first floppy disk
	mov dh,	0			; starting head
	mov ch,	0			; cylinder
	mov cl, 2			; start reading from second sector (i.e. after boot sector)
	
	int 0x13			; issue read

	jc disk_error		; catch errors
	mov si, DISK_SUCCESS_MSG
	call printf
	popa
	ret
	disk_error:
		mov si, DISK_ERROR_MSG
		call printf
		jmp $

DISK_ERROR_MSG db "An error occured while reading disk", 0x0a, 0x0d, 0
DISK_SUCCESS_MSG db "Succefully read from disk", 0x0a, 0x0d, 0

