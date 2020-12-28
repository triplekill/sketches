global main
extern printf

section .bss
struc PROCESSOR_NUMBER
   .Group:    resw 1
   .Number:   resb 1
   .Reserved: resb 1
endstruc

section .data
fmt: db "Group: %u, Number: %u", 0xA, 0

; TEB->CurrentIdealProcessor
section .text
main:
    push  rdi
    sub   rsp, 30h
    lea   rax, [rsp+PROCESSOR_NUMBER]
    mov   rdi, rax
    xor   eax, eax
    mov   ecx, 4
    rep   stosb
    mov   rax, qword [gs:abs 30h]
    mov   eax, dword [rax+1744h]
    mov   dword [rsp+PROCESSOR_NUMBER], eax
    movzx eax, byte [rsp+PROCESSOR_NUMBER.Number]
    movzx ecx, word [rsp+PROCESSOR_NUMBER.Group]
    mov   r8d, eax
    mov   edx, ecx
    lea   rcx, [rel fmt]
    call  printf
    xor   eax, eax
    add   rsp, 30h
    pop   rdi
    ret
