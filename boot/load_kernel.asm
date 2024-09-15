
; -----------------------------------------------------------------------------
; load_kernel: loads the kernel code from disk into KERNEL_OFFSET address.
; -----------------------------------------------------------------------------
load_kernel:
	mov si, MSG_LOAD_KERNEL		; print a message to say we are loading the kernel
	call printf
	
	mov bx, 0x0000				; The ES:BX value specifies the physical memory address
	mov es, bx					; the disk will be loaded
	mov bx, KERNEL_OFFSET		
	mov al, 15					; the number of 512b sectors to read
	call load_disk
	ret

; -----------------------------------------------------------------------------
; load_disk loads sectors to ES:BX memory address from first floppy disk 
;			'al' should have the amount of sectors to read
; -----------------------------------------------------------------------------
load_disk:
	pusha
                        
    mov ah, 0x02        		; BIOS read sectors function
    mov dl, [BOOT_DRIVE]	    ; read from disk containing the boot sector
    mov dh, 0           		; head 0
    mov ch, 0           		; cylinder 0
    mov cl, 2           		; start reading from second sector (i.e., skip this boot sector)

    int 0x13           	 		; issue BIOS function to read from disk

    jc disk_error       		; catch errors

    mov si, DISK_SUCCESS_MSG	; print success
    call printf

	mov dx, [KERNEL_OFFSET] 	; print the first byte loaded into memory
	call printh

    popa
    ret

    disk_error:
        mov si, DISK_ERROR_MSG
        call printf
		mov [DISK_ERROR_CODE], ah
		mov dx, [DISK_ERROR_CODE] 
		call printh
        jmp $

DISK_ERROR_CODE db 0x00 
DISK_ERROR_MSG db "An error occured while reading disk", 0x0a, 0x0d, 0
DISK_SUCCESS_MSG db "Succefully read from disk", 0x0a, 0x0d, 0