printf:
	pusha
	mov ah, 0x0e	; int=10/ah=0x0e -> BIOS tele-typw output
	printf_loop:
		mov al, [bx]
		cmp al, 0
		jne print_char
		popa
		ret
	print_char:
		int 0x10
		add bx, 1
		jmp printf_loop
