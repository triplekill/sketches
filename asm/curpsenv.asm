global main
extern printf

; the code below should in theory be equivalent to the following C code
; #include <intrin.h>
; #include <stdio.h>
;
; int main(void) {
;   void *env = *(void **)((unsigned char *)__readgsqword(0x60) + 0x20);
;   unsigned __int64 sz = *(unsigned __int64 *)((unsigned char *)env + 0x3f0);
;   env = *(void **)((unsigned char *)env + 0x80);
;   for (int i = 0; i < sz / sizeof(wchar_t); i++) {
;     wchar_t c = *(wchar_t *)env;
;     printf("%wc", L'\0' != c ? c : L'\n');
;     ((wchar_t *)env)++;
;   }
;
;   return 0;
; }

section .data
fmt: db 0x25, 0x77, 0x63, 0x00     ; "%wc"

section .text
main:
    sub    rsp, 58h
    mov    rax, qword [gs:abs 60h] ; PEB
    mov    rax, qword [rax+20h]    ; PEB->ProcessParameters
    mov    qword [rsp+30h], rax
    mov    rax, qword [rsp+30h]    ; RTL_USER_PROCESS_PARAMETERS
    mov    rax, qword [rax+3f0h]   ; RTL_USER_PROCESS_PARAMETERS->EnvironmentSize
    mov    qword [rsp+38h], rax
    mov    rax, qword [rsp+30h]
    mov    rax, qword [rax+80h]    ; RTL_USER_PROCESS_PARAMETERS->Environment
    mov    qword [rsp+30h], rax
    mov    dword [rsp+24h], 0      ; loop
    jmp    __label2
__label1:
    mov    eax, dword [rsp+24h]
    inc    eax
    mov    dword [rsp+24h], eax
__label2:
    movsxd rax, dword [rsp+24h]
    mov    qword [rsp+40h], rax
    xor    edx, edx
    mov    rax, qword [rsp+38h]
    mov    ecx, 2
    div    rcx
    mov    rcx, qword [rsp+40h]
    cmp    rcx, rax
    jnc    __label5
    mov    rax, qword [rsp+30h]    ; getting symbol
    movzx  eax, word [rax]
    mov    word [rsp+20h], ax
    movzx  eax, word [rsp+20h]     ; what should be printed
    test   eax, eax
    jz     __label3
    movzx  eax, word [rsp+20h]
    mov    dword [rsp+28h], eax
    jmp    __label4
__label3:
    mov    dword [rsp+28h], 10
__label4:
    mov    edx, dword [rsp+28h]
    lea    rcx, [rel fmt]
    call   printf
    mov    rax, qword [rsp+30h]    ; end of step
    add    rax, 2
    mov    qword [rsp+30h], rax
    jmp    __label1
__label5:
    xor    eax, eax
    add    rsp, 58h
    ret
