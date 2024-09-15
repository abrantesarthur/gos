
; -----------------------------------------------------------------------------
; GLOBAL DESCRIPTOR TABLE (32 bit mode)
;	It's comprised of 8-byte Segment descriptors, each of which defines the following
;	properties of a protected-mode segment:
;		1. Base Address (32 bits): where the segment starts in memory
;		2. Segment Limit (20 bits): the size of the segment
;		3. Various flags, affeting the priviledge of code within it, etc.
;	These 8-byte segments are indexed by special segment registers.
; 	Important: these bits are not continuous. The 20 bits of the Segment Limit,
;	for instance, are split in a continous 16 and 4 bit chunks.
; -----------------------------------------------------------------------------
gdt_start:

; The first 8-byte segment descriptor must be null!
gdt_null:
	dd 0x0			; dd stands for "define double word" (4 bytes)
	dd 0x0			; we use two dd instructions to define 8 bytes

; -----------------------------------------------------------------------------
; The code Segment descriptor
; base=0x0, limit=0xfffff -> the code segment begins at 0x0 and ends at 0xfffff
; 1st flags: (present)1 (privilege)00 (descriptor type)1 -> 1001b
; type flags: (code)1 (conforming)0 (readable)1 (accessed)0 -> 1010b
; 2nd flags: (granularity)1 (32-bit default)1 (64-bit seg)0 (AVL)0 -> 1100b
; -----------------------------------------------------------------------------
gdt_code:
	dw 0xffff		; Limit (bits 0-15)
	dw 0x0			; Base (bits 0-15)
	db 0x0			; Base (bits 16-23)
	db 10011010b	; 1st flags, type flags
	db 11001111b	; 2nd flags, Limit (bits 16-19)
	db 0x0			; Base (bits 24-31)

; -----------------------------------------------------------------------------
; The data segment descriptor
; Same as code segment except for the type flags:
; type flags: (code)0 (expand down)0 (writable)1 (accessed)0 -> 0010b
; -----------------------------------------------------------------------------
gdt_data:
	dw 0xffff		; Limit (bits 0-15)
	dw 0x0			; Base (bits 0-15)
	db 0x0			; Base (bits 16-23)
	db 10010010b	; 1t flags, type flags
	db 11001111b	; 2nd flags, Limit (bits 16-19)
	db 0x0			; Base (bits 24-31)

gdt_end:

; -----------------------------------------------------------------------------
; GDT descriptor
;	Holds information about the GDT size and start address, which are needed
;	by the CPU to setup the GDT.
; -----------------------------------------------------------------------------
gdt_descriptor:
	dw gdt_end - gdt_start - 1		; bits 0-15: GDT size, always one less than true
	dd gdt_start					; bits 16-31: GDT start address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start