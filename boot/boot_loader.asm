; -----------------------------------------------------------------------------
; BOOT_LOADER:	This first 512 bytes are initially in some physical disk. It's
;				identified by the BIOS routine as the intended boot sector by
;				virtue of its last byte being the magic number 0xaa55. Hence,
;				it's read into the physical memory address 0x7c00 by the BIOS,
;				which instructs the CPU to begin executing its instructions.
; -----------------------------------------------------------------------------
[org 0x7c00]				; tell the assembler the address where BIOS loads this
							; boot sector so it can correctly address labels herein.
							; this is equivalent to setting the special data segment
							; DS register to 0x7c0.

mov bp, 0x7c00				; set the stack base pointer to be right where the boot sector
mov sp, bp					; above the boot sector is loaded, growing downward.

mov [BOOT_DRIVE], dl		; BIOS stores in 'dl' the disk wherein it found this sector.
							; We save this disk number in memory so we can safely modify
							; 'dl' without losing this information.


KERNEL_OFFSET equ 0x8c00	; define a constant specifying the address where we'll load
							; load the kernel 4k bytes above the stack base.


mov si, MSG_REAL_MODE		; print a message to say we are in real mode
call printf

; TODO: eventually read the kernel from disk
; call load_kernel			; load the kernel into memory

call switch_to_pm			; we never return from here

jmp $

; Global variables
BOOT_DRIVE		db 0
MSG_REAL_MODE	db "Started in 16-bit real mode", 0x0a, 0x0d, 0
MSG_LOAD_KERNEL	db "Loading kernel into memory.", 0x0a, 0x0d, 0

; -----------------------------------------------------------------------------
; load_kernel: loads the kernel code from disk into KERNEL_OFFSET address.
; -----------------------------------------------------------------------------
load_kernel:
	mov si, MSG_LOAD_KERNEL		; print a message to say we are loading the kernel
	call printf
	
	mov bx, 0x0000				; The ES:BX value specifies the physical memory address
	mov es, bx					; the disk will be loaded
	mov bx, KERNEL_OFFSET		
	mov al, 1					; the number of 512b sectors to read
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

%include "print/printf.asm"
%include "print/printh.asm"
%include "gdt.asm"

; -----------------------------------------------------------------------------
; Switch to 32-bit protected mode
; -----------------------------------------------------------------------------
switch_to_pm:
	cli						; switch off interrupts until we have set-up the 
							; protected mode interrupt vector. Otherwise 
							; interrupts will fail

	lgdt [gdt_descriptor]	; load the global descriptor table, which defines
							; the protected mode segments (e.g. for code and
							; data), into the GDTR register.
	
	mov eax, cr0			; to make the switch to protected mode, we set 
	or eax, 0x1				; the first byte of CR0, a control regisiter
	mov cr0, eax

	jmp CODE_SEG:init_pm	; Make a far jump (i.e. to a new segment) to our
							; 32-bit code. This also forces the CPU to finnish
							; any jobs in its pipeline of instructions, before
							; we can be sure that the switch is complete.
							; The physical address we jump to is calculated by
							; the CPU using the base address from the code segment
							; descriptor (i.e., 0) and the offset (i.e., init_pm
							; which is 0x7c00 + its offset in the boot sector).


[bits 32]					; Tell the assembler that we are in 32-bit mode
; Initialize registers and the stack once in PM.
init_pm:
	mov ax, DATA_SEG		; Now in protected mode, our old segments are
	mov ds, ax				; meaningless, so we point our segment registers
	mov ss, ax				; to the data selector we defined in GDT.
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0x90000		; Update stack right at the top of the free space
	mov esp, ebp

	call BEGIN_PM

; -----------------------------------------------------------------------------
; This is where we arrive after switching to and initializing protected mode
; -----------------------------------------------------------------------------
BEGIN_PM:
	mov ebx, MSG_PROT_MODE
	call print_pm
	jmp $

	call KERNEL_OFFSET

	jmp $					; hang

MSG_PROT_MODE	db "Succesfully landed in 32-bit long mode", 0x0a, 0x0d, 0


;------------------------------------------------------------------------------
; print_pm:		in 32-bit protected mode, we no longer have access to the useful 
;				BIOS functions we use in the printf and printh routines above.
;				We define a new print_pm function that prints characters to
;				the screen by writing the the Virtual Graphics Array (VGA)
;				memory-mapped region.
; -----------------------------------------------------------------------------
; Define some contants
SCREEN_ADDR equ 0xb8000			; the 80x25 byte VGA memory-mapped region 
WHITE_ON_BLACK equ 0x0f

; print_pm prints a null terminated string pointed to by EBX
print_pm:
	pusha
	mov edx, SCREEN_ADDR		; set edx to start of video memory

printf_lm_loop:
	mov al, [ebx]				; store the character at EBX in AL
	mov ah, WHITE_ON_BLACK		; store attributes in AH

	cmp al, 0					; if (al == 0), at end of string, so
	je printf_lm_done				; jump to done

	mov [edx], ax				; else, store char and attributes at screen cell

	add ebx, 1					; go to next char
	add edx, 2					; go to next cell
	jmp printf_lm_loop

printf_lm_done:
	popa				
	ret

;------------------------------------------------------------------------------
; The boot sector must fit in 512 bytes, with the last 2 being a magic number.
; -----------------------------------------------------------------------------
times 510-($-$$) db 0
dw 0xaa55