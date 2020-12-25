global main
extern printf

section .data
fmt: db "%u", 0xA, 0

section .text
; translation this code, for example, in C will look like
; printf("%u\n", (*(unsigned char (*)[64])0x7FFE0274)[21]);
main:
    sub   rsp, 28h
    mov   eax, 1
    imul  rax, rax, 15h             ; ProcessorFeatures[21] !!!
    movzx eax, byte [rax+7FFE0274h] ; +0x274 UCHAR ProcessorFeatures[64]
    mov   edx, eax
    lea   rcx, [rel fmt]
    call  printf                    ; 1 means virt. is enabled
    xor   eax, eax
    add   rsp, 28h
    ret
