global main
extern printf

section .data
fmt: db "%d.%d", 0xA, 0

section .text
main:
    sub   rsp, 38h
    mov   qword [rsp+20h], 7FFE026Ch
    mov   eax, 4
    imul  rax, rax, 1
    mov   ecx, 4
    imul  rcx, rcx, 0
    mov   rdx, qword [rsp+20h]
    mov   r8d, dword [rdx+rax]
    mov   rax, qword [rsp+20h]
    mov   edx, dword [rax+rcx]
    lea   rcx, [rel fmt]
    call  printf
    xor   eax, eax
    add   rsp, 38h
    ret
