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