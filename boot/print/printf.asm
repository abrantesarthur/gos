
; -----------------------------------------------------------------------------
; printf outputs contents at SI address to the screen
; -----------------------------------------------------------------------------
printf:
	pusha
	mov ah, 0x0e	; int=10/ah=0x0e -> BIOS tele-type output
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