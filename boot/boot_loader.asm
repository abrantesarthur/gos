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

mov bp, 0x9000				; set the stack base pointer to be right where the boot sector
mov sp, bp					; above the boot sector is loaded, growing downward.

mov [BOOT_DRIVE], dl		; BIOS stores in 'dl' the disk wherein it found this sector.
							; We save this disk number in memory so we can safely modify
							; 'dl' without losing this information.

KERNEL_OFFSET equ 0x1000	; where we'll load the kernel

mov si, MSG_REAL_MODE		; print a message to say we are in real mode
call printf

; TODO: eventually read the kernel from disk
call load_kernel			; load the kernel into memory

call switch_to_pm			; we never return from here

jmp $

; Global variables
BOOT_DRIVE		db 0
MSG_REAL_MODE	db "Started in 16-bit real mode", 0x0a, 0x0d, 0
MSG_LOAD_KERNEL	db "Loading kernel into memory.", 0x0a, 0x0d, 0
MSG_PROT_MODE	db "Succesfully landed in 32-bit long mode", 0x0a, 0x0d, 0

%include "load_kernel.asm"
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
	mov cr0, eax			; after this point, we are in PM!

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

	mov ebp, 0x9000		; Update stack right at the top of the free space
	mov esp, ebp

	call BEGIN_PM

; -----------------------------------------------------------------------------
; This is where we arrive after switching to and initializing protected mode
; -----------------------------------------------------------------------------
BEGIN_PM:
	mov ebx, MSG_PROT_MODE
	call print_pm

	call KERNEL_OFFSET		; there must be some function at the kernel loading address!

	jmp $					; hang


%include "print/print_pm.asm"

;------------------------------------------------------------------------------
; The boot sector must fit in 512 bytes, with the last 2 being a magic number.
; -----------------------------------------------------------------------------
times 510-($-$$) db 0
dw 0xaa55