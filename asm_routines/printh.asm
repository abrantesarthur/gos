; printh outputs the hexadecimal representation of bits present in DX
printh:
	pusha						; save register state
	mov ax, 4					; number of characters to print
	mov cl, 12					; number of bits to shift
	mov di, HEX_PATTERN + 2		; address to where copy bits 
printh_loop:
	cmp ax, 0					; if printed all characters
	je printh_end				;	exit function
								; else
	mov bx, dx					;	copy bits to bx
	shr bx, cl					;	shift right 4 next bits to be printed
	and bx, 0x000f				;	mask 4 bits to be printed
	mov bx, [HEX_TABLE + bx]	;	get hex value of bits
	mov [di], bl				;	copy hex representation to print address
	
	sub ax, 1					; update control registers
	sub cl, 4
	add di, 1
	jmp printh_loop
printh_end:
	mov si, HEX_PATTERN
	call printf
	popa
	ret

HEX_PATTERN: db "0x****", 0x0a, 0x0d, 0
HEX_TABLE: db "0123456789abcdef"

