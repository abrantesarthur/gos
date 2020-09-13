[bits 32]						; 32 bit mode printf routine

; Define some contants
SCREEN_ADDR equ 0xb8000
WHITE_ON_BLACK equ 0x0f

; print_pm prints a null terminated string pointed to by EBX
printf_pm:
	pusha
	mov edx, SCREEN_ADDR		; set edx to start of video memory

printf_loop:
	mov al, [ebx]				; store the character at EBX in AL
	mov ah, WHITE_ON_BLACK		; Store attributes in AH

	cmp al, 0					; if (al == 0), at end of string, so
	je printf_done				; jump to done
	
	mov [edx], ax				; store char and attributes at screen cell

	add ebx, 1					; go to next char
	add edx, 2					; go to next cell

printf_done:
	popa
	ret
