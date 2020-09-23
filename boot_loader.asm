; -----------------------------------------------------------------------------
; BOOT_LOADER:	this first 512 bytes are read into memory by the BIOS routine.
;				it switches the CPU to 64-bit long mode
; -----------------------------------------------------------------------------
[org 0x7c00]				; tell the assembler the address where BIOS
							; loads the boot sector

mov bp, 0x9000				; set the stack
mov sp, bp

mov si, MSG_REAL_MODE
call printf

call switch_to_lm			; we never return from here

jmp $

; -----------------------------------------------------------------------------
; printf outputs contents at SI address to the screen
; -----------------------------------------------------------------------------
printf:
	pusha
	mov ah, 0x0e	; int=10/ah=0x0e -> BIOS tele-typw output
	printf_loop:
		mov al, [si]
		cmp al, 0
		jne print_char
		popa
		ret
	print_char:
		int 0x10
		add si, 1
		jmp printf_loop

; -----------------------------------------------------------------------------
; Global Descriptor Table
; -----------------------------------------------------------------------------
gdt_start:

gdt_null:							; the mandatory null descriptor
	dd 0x0							; 8 bytes = one GDT segment
	dd 0x0

gdt_code:	; the code segment descriptor
	; base=0x0, limit=0xfffff,
	; 1st flags: (present)1 (privilege)00 (descriptor type)1 -> 1001b
	; type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
	; 2nd flags: (granularity)1 (32-bit default)1 (64-bit seg)0 (AVL)0 -> 1100b
	dw 0xffff		; Limit (bits 0-15)
	dw 0x0			; Base (bits 0-15)
	db 0x0			; Base (bits 16-23)
	db 10011010b	; 1st flags, type flags
	db 11001111b	; 2nd flags, Limit (bits 16-19)
	db 0x0			; Base (bits 24-31)

gdt_data:	; the data segment descriptor		
	; Same as code segment except for the type flags:
	; type flags: (code)0 (expand down)0 (writable)1 (accessed)0 -> 0010b
	dw 0xffff		; Limit (bits 0-15)
	dw 0x0			; Base (bits 0-15)
	db 0x0			; Base (bits 16-23)
	db 10010010b	; 1t flags, type flags
	db 11001111b	; 2nd flags, Limit (bits 16-19)
	db 0x0			; Base (bits 24-31)

gdt_end:

; GDT descriptor
gdt_descriptor:
	dw gdt_end - gdt_start - 1		; GDT size, always one less than true
	dd gdt_start					; GDT start address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; -----------------------------------------------------------------------------
; Switch to long mode
; -----------------------------------------------------------------------------
switch_to_lm:
	cli						; switch off interrupts until we have set-up the 
							; protected mode interrupt vector otherwise 
							; interrupts will fail

	lgdt [gdt_descriptor]	; load the global descriptor table, which defines
							; the protected mode segments (e.g. for code and
							; data)
	
	mov eax, cr0			; to make the switch to protected mode, we set 
	or eax, 0x1				; the first byte of CR0, a control regisiter
	mov cr0, eax

	jmp CODE_SEG:init_lm	; Make a far jump (i.e. to a new segment) to our
							; 64-bit code. This also forces the CPU to flush
							; its cache of pre-fetched and real-mode decoded
							; instructions, whicc could cause problems.

[bits 64]
; Initialize registers and the stack once in PM.
init_lm:
	mov ax, DATA_SEG		; Now in protected mode, our old segments are
	mov ds, ax				; meaningless, so we point our segment registers
	mov ss, ax				; to the data selector we defined in GDT.
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0x90000
	mov esp, ebp

	call BEGIN_LM

; -----------------------------------------------------------------------------
; This is where we arrive after switching to and initializing long mode
; -----------------------------------------------------------------------------
BEGIN_LM:
	mov rbx, MSG_PROT_MODE
	call printf_lm

	jmp $					; hang

; Global variables
MSG_REAL_MODE db "Started in 16-bit real mode", 0
MSG_PROT_MODE db "Succesfully landed in 64-bit long mode", 0

;------------------------------------------------------------------------------
; printf_lm
; -----------------------------------------------------------------------------

; Define some contants
SCREEN_ADDR equ 0xb8000
WHITE_ON_BLACK equ 0x0f

; print_pm prints a null terminated string pointed to by EBX
printf_lm:
	push rdx
	push rax
	mov rdx, SCREEN_ADDR		; set edx to start of video memory

printf_lm_loop:
	mov al, [rbx]				; store the character at EBX in AL
	mov ah, WHITE_ON_BLACK		; Store attributes in AH

	cmp al, 0					; if (al == 0), at end of string, so
	je printf_lm_done				; jump to done
	
	mov [rdx], ax				; store char and attributes at screen cell

	add rbx, 1					; go to next char
	add rdx, 2					; go to next cell
	jmp printf_lm_loop

printf_lm_done:
	pop rax
	pop rdx
	ret
; Bootsector padding
times 510-($-$$) db 0
dw 0xaa55

