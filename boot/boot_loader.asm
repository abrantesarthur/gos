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

mov bp, 0x8c00				; set the stack base pointer safely above the boot sector
mov sp, bp					; keep in mind that the stack grows downwards, so it has 
							; 0x8c00 - 0x7c00 = 0x1000 (i.e., 4k) bytes of space.

mov [BOOT_DRIVE], dl		; BIOS stores in 'dl' the disk wherein it found this sector.
							; We save this disk number in memory so we can safely modify
							; 'dl' without losing this information.


KERNEL_OFFSET equ 0x9c00	; define a constant specifying the address where we'll load
							; load the kernel 4k bytes above the stack base.


mov si, MSG_REAL_MODE		; print a message to say we are in real mode
call printf

call load_kernel			; load the kernel into memory

; TODO: remove
jmp $

call switch_to_lm			; we never return from here

jmp $

; Global variables
BOOT_DRIVE		db 0
MSG_REAL_MODE	db "Started in 16-bit real mode", 0x0a, 0x0d, 0
MSG_PROT_MODE	db "Succesfully landed in 64-bit long mode", 0x0a, 0x0d, 0
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
		jmp $


; -----------------------------------------------------------------------------
; printf outputs contents at SI address to the screen
; -----------------------------------------------------------------------------
printh:                                                                       
    pusha                       ; save register state                         
    mov ax, 4                   ; number of characters to print               
    mov cl, 12                  ; number of bits to shift                     
    mov di, HEX_PATTERN + 2     ; address to where copy bits                  
printh_loop:                                                                  
    cmp ax, 0                   ; if printed all characters                   
    je printh_end               ;   exit function                             
                                ; else                                        
    mov bx, dx                  ;   copy bits to bx                           
    shr bx, cl                  ;   shift right 4 next bits to be printed     
    and bx, 0x000f              ;   mask 4 bits to be printed                 
    mov bx, [HEX_TABLE + bx]    ;   get hex value of bits                     
    mov [di], bl                ;   copy hex representation to print address  
                                                                              
    sub ax, 1                   ; update control registers                    
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
; base=0x0, limit=0xfffff
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

; GDT descriptor
gdt_descriptor:
	dw gdt_end - gdt_start - 1		; GDT size, always one less than true
	dd gdt_start					; GDT start address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; -----------------------------------------------------------------------------
; Switch 32-bit to long mode
; -----------------------------------------------------------------------------
switch_to_lm:
	cli						; switch off interrupts until we have set-up the 
							; protected mode interrupt vector. Otherwise 
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

	call KERNEL_OFFSET

	jmp $					; hang


;------------------------------------------------------------------------------
; printf_lm:	in 32-bit long mode, we no longer have access to the useful 
;				BIOS functions we use in the printf and printh routines above.
;				We define a new printf_lm function that prints characters to
;				the screen by writing the the Virtual Graphics Array (VGA)
;				memory-mapped region.
; -----------------------------------------------------------------------------

; Define some contants
SCREEN_ADDR equ 0xb8000			; the 80x25 byte VGA memory-mapped region 
WHITE_ON_BLACK equ 0x0f

; print_lm prints a null terminated string pointed to by EBX
printf_lm:
	pusha						; save all registers in the stack
	mov rdx, SCREEN_ADDR		; set edx to start of video memory

printf_lm_loop:
	mov al, [rbx]				; store the character at EBX in AL
	mov ah, WHITE_ON_BLACK		; store attributes in AH

	cmp al, 0					; if (al == 0), at end of string, so
	je printf_lm_done				; jump to done

	mov [rdx], ax				; else, store char and attributes at screen cell

	add rbx, 1					; go to next char
	add rdx, 2					; go to next cell
	jmp printf_lm_loop

printf_lm_done:
	popa						; restore all resgisters
	ret

;------------------------------------------------------------------------------
; The boot sector must fit in 512 bytes, with the last 2 being a magic number.
; -----------------------------------------------------------------------------

times 510-($-$$) db 0
dw 0xaa55

times 1 dw 0xdada
times 511 dw 0xdede
