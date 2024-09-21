; -----------------------------------------------------------------------------
; print_mem checks if the memory range from SI to DI is all zeros
; Prints "T" if all zeros, "F" otherwise
; -----------------------------------------------------------------------------
print_mem:
    pusha

.check_loop:
    mov dx, [si]            ; Load the word (16 bits) at address in SI into DX
    test dx, dx             ; Check if DX is zero
    jnz .not_all_zeros      ; If not zero, jump to print "FALSE"

    add si, 2               ; Move to the next word (2 bytes)
    cmp si, di              ; Compare current address with end address
    jle .check_loop         ; If current <= end, continue loop

    ; If we've reached here, all values were zero
    mov si, true_str
    jmp .print_result

.not_all_zeros:
    mov si, false_str

.print_result:
    call printf
    popa
    ret

true_str db "T", 0x0a, 0x0d, 0
false_str db "F", 0x0a, 0x0d, 0