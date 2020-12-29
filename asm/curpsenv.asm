global main

extern free
extern malloc
extern memcpy
extern printf

; the code below should in theory be equivalent to the following C code
; #include <intrin.h>
; #include <stdio.h>
; #include <string.h>
;
; int main(void) {
;   void *upp = *(void **)((unsigned char *)__readgsqword(0x60) + 0x20);
;   unsigned __int64 sz = *(unsigned __int64 *)((unsigned char *)upp + 0x3f0);
;   void *env = *(void **)((unsigned char *)upp + 0x80);
;   wchar_t *buf = (wchar_t *)malloc(sz);
;   memcpy(buf, env, sz);
;   for (int i = 0; i < sz / sizeof(wchar_t); i++) {
;     printf("%wc", buf[i]);
;     if (buf[i + 1] == L'\0') printf("\n");
;   }
;   free(buf);
;
;   return 0;
; }

section .data
fmt: db 0x25, 0x77, 0x63, 0x00     ; "%wc"
nil: db 0x0A, 0x00                 ; new line

section .text
main:
    sub    rsp, 58h
    mov    rax, qword [gs:abs+60h] ; PEB
    mov    rax, qword [rax+20h]    ; PEB->ProcessParameters
    mov    qword [rsp+38h], rax
    mov    rax, qword [rsp+38h]    ; RTL_USER_PROCESS_PARAMETERS
    mov    rax, qword [rax+3f0h]   ; RTL_USER_PROCESS_PARAMETERS->EnvironmentSize
    mov    qword [rsp+30h], rax
    mov    rax, qword [rsp+38h]
    mov    rax, qword [rax+80h]    ; RTL_USER_PROCESS_PARAMETERS->Environment
    mov    qword [rsp+40h], rax
    mov    rcx, qword [rsp+30h]    ; allocating memory block (but not check)
    call   malloc
    mov    qword [rsp+28h], rax
    mov    r8, qword [rsp+30h]     ; copy Environment block
    mov    rdx, qword [rsp+40h]
    mov    rcx, qword [rsp+28h]
    call   memcpy
    mov    dword [rsp+20h], 0      ; loop
    jmp    __label2
__label1:
    mov    eax, dword [rsp+20h]
    inc    eax
    mov    dword [rsp+20h], eax
__label2:
    movsxd rax, dword [rsp+20h]
    mov    qword [rsp+48h], rax
    xor    edx, edx
    mov    rax, qword [rsp+30h]
    mov    ecx, 2
    div    rcx
    mov    rcx, qword [rsp+48h]
    cmp    rcx, rax
    jnc    __label4
    movsxd rax, dword [rsp+20h]
    mov    rcx, qword [rsp+28h]
    movzx  eax, word [rcx+rax*2]
    mov    edx, eax
    lea    rcx, [rel fmt]
    call   printf
    mov    eax, dword [rsp+20h]
    inc    eax
    cdqe
    mov    rcx, qword [rsp+28h]
    movzx  eax, word [rcx+rax*2]
    test   eax, eax
    jnz    __label3
    lea    rcx, [rel nil]
    call   printf
__label3:
    jmp    __label1
__label4:
    mov    rcx, qword [rsp+28h]    ; release allocated memory
    call   free
    xor    eax, eax
    add    rsp, 58h
    ret
