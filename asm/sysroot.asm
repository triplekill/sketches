; KUSER_SHARED_DATA->NtSystemRoot
; printf("%ws\n", *(wchar_t (*)[260])0x7FFE0030);
;
; Particularly same technique is used inside RtlGetNtSystemRoot
global main
extern printf

section .data
fmt: db "%ws", 0xA, 0

section .text
main:
    sub  rsp, 28h
    mov  edx, 7FFE0030h
    lea  rcx, [rel fmt]
    call printf
    xor  eax, eax
    add  rsp, 28h
    ret
