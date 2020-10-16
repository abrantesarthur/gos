[org 0x7c00]

mov bp, 0x8000
mov sp, bp

mov bx, 0x9000				; read disk to ES:BX = 0000:9000 memory address
mov al, 2 					; read 1 sector
call load_disk


mov dx, [$ + 512] 
call printh

BOOT_DRIVE: db 0

; load AL sectors to ES:BX from first floppy disk
load_disk:
    pusha
                        ; interrupt setup
    mov ah, 0x02        ; read sectors mode
    mov dl, 0x80        ; from first floppy disk
    mov dh, 0           ; starting head
    mov ch, 0           ; cylinder
    mov cl, 2           ; start reading from second sector (i.e. after boot se

    int 0x13            ; issue read

    jc disk_error       ; catch errors
    mov si, DISK_SUCCESS_MSG
    call printf
    popa
    ret
    disk_error:
        mov si, DISK_ERROR_MSG
        call printf
        jmp $
 
DISK_ERROR_MSG db "An error occured while reading disk", 0x0a, 0x0d, 0
DISK_SUCCESS_MSG db "Succefully read from disk", 0x0a, 0x0d, 0

; ----------------------------------------------------------------------------
; printf outputs contents at SI address to the screen
; ----------------------------------------------------------------------------
printf:                                                                       
    pusha                                             
    mov ah, 0x0e    ; int=10/ah=0x0e -> BIOS tele-typw output                 
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
                                                                               
                                                                              
; ----------------------------------------------------------------------------
; printf outputs contents at SI address to the screen                         
; ----------------------------------------------------------------------------
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

times 510-($-$$) db 0
dw 0xaa55

times 256 dw 0xbada
times 256 dw 0xface
