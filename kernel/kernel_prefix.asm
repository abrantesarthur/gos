; -----------------------------------------------------------------------------
; kernel_prefix: these are the very first instructions of our kernel code. They
;                ensure that we always jump to the main() function in our kernel
;                code, regardless of where it's loaded in memory.
; -----------------------------------------------------------------------------
[bits 32]
[extern main]
call main
jmp $
