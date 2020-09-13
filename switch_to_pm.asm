[bits 16]
; Switch to protected mode
switch_to_pm:
	cli						; switch off interrupts until we have set-up the 
							; protected mode interrupt vector otherwise 
							; interrupts will fail

	lgdt [gdt_descriptor]	; load the global descriptor table, which defines
							; the protected mode segments (e.g. for code and
							; data)
	
	mov eax, cr0			; to make the switch to protected mode, we set 
	or eax, 0x1				; the first byte of CR0, a control regisiter
	mov cr0, eax

	jmp CODE_SEG:init_pm	; Make a far jump (i.e. to a new segment) to our
							; 32-bit code. This also forces the CPU to flush
							; its cache of pre-fetched and real-mode decoded
							; instructions, whicc could cause problems.

[bits 32]
; Initialize registers and the stack once in PM.
init_pm:
	mov ax, DATA_SEG		; Now in protected mode, our old segments are
	mov ds, ax				; meaningless, so we point our segment registers
	mov ss, ax				; to the data selector we defined in GDT.
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0x90000
	mov esp, ebp

	call BEGIN_PM
