global main
extern printf

section .data
fmt: db "%.2d: %u", 0xA, 0

section .text
IsProcessorFeaturePresent:
    mov   dword [rsp+8h], ecx
    cmp   dword [rsp+8h], 40h
    jnc   __label1
    mov   eax, dword [rsp+8h]
    add   eax, 7FFE0274h
    mov   eax, eax
    mov   al, byte [rax]
    jmp   __label2
__label1:
    xor   al, al
__label2:
    ret

main:
    sub   rsp, 38h
    mov   dword [rsp+20h], 0   ; loop counter (i = 0)
    jmp   __less
__incr:
    mov   eax, dword [rsp+20h] ; increment block
    inc   eax
    mov   dword [rsp+20h], eax
__less:
    cmp   dword [rsp+20h], 40h ; loop condition (i < 64)
    jnc   __done
    mov   ecx, dword [rsp+20h]
    call  IsProcessorFeaturePresent
    movzx eax, al
    mov   r8d, eax
    mov   edx, dword [rsp+20h]
    lea   rcx, [rel fmt]
    call  printf
    jmp   __incr
__done:
    xor   eax, eax
    add   rsp, 38h
    ret
