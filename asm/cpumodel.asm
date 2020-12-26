global main
global getlasterror

extern printf
extern malloc
extern free
extern _wsetlocale
extern NtQuerySystemInformation
extern RtlNtStatusToDosError
extern __imp_FormatMessageW
extern __imp_GetLastError
extern __imp_LocalFree

section .bss
locale: resb 2

section .data
unknown: db "[?] Unknown error has been occured.", 0xA, 0
errfmt:  db "[!] %.*ws", 0xA, 0
fatal:   db "LocaleFree (%lu) fatl error.", 0xA, 0
memerr:  db "[!] Unable alocate memory block.", 0xA, 0
fmt:     db "%s", 0xA, 0

section .text
getlasterror:
    mov  dword [rsp+8], ecx
    sub  rsp, 58h
    mov  qword [rsp+48h], 0
    cmp  dword [rsp+60h], 0
    jz   _label1
    mov  ecx, dword [rsp+60h]
    call RtlNtStatusToDosError
    mov  dword [rsp+40h], eax
    jmp  _label2
_label1:
    call near [rel __imp_GetLastError]
    mov  dword [rsp+40h], eax
_label2:
    mov  qword [rsp+30h], 0
    mov  dword [rsp+28h], 0
    lea  rax, [rsp+48h]
    mov  qword [rsp+20h], rax
    mov  r9d, 400h
    mov  r8d, dword [rsp+40h]
    xor  edx, edx
    mov  ecx, 1100h
    call near [rel __imp_FormatMessageW]
    mov  dword [rsp+44h], eax
    cmp  dword [rsp+44h], 0
    jnz  _label3
    lea  rcx, [rel unknown]
    call printf
    jmp  _label4
_label3:
    mov  eax, dword [rsp+44h]
    sub  rax, 2
    mov  r8, qword [rsp+48h]
    mov  edx, eax
    lea  rcx, [rel errfmt]
    call printf
_label4:
    mov  rcx, qword [rsp+48h]
    call near [rel __imp_LocalFree]
    test rax, rax
    jz   _label5
    call near [rel __imp_GetLastError]
    mov  edx, eax
    lea  rcx, [rel fatal]
    call printf
_label5:
    add  rsp, 58h
    ret

main:
    sub  rsp, 38h
    lea  rdx, [rel locale]
    mov  ecx, 2
    call _wsetlocale
    mov  dword [rsp+24h], 0
    lea  r9, [rsp+24h]
    xor  r8d, r8d
    xor  edx, edx
    mov  ecx, 69h                    ; SystemProcessorBrandString
    call NtQuerySystemInformation
    mov  dword [rsp+20h], eax
    cmp  dword [rsp+20h], 0xC0000004 ; checking STATUS_INFO_LENGTH_MISMATCH
    jz   _label6
    mov  ecx, dword [rsp+20h]
    call getlasterror                ; if NTSTATUS is not STATUS_INFO_LENGTH_MISMATCH
    mov  eax, 1                      ; then show a reason and leave (return 1)
    jmp  _label9
_label6:
    mov  eax, dword [rsp+24h]
    mov  ecx, eax
    call malloc                      ; allocate buffer
    mov  qword [rsp+28h], rax
    cmp  qword [rsp+28h], 0          ; checking ability to allocate memory block
    jnz  _label7
    lea  rcx, [rel memerr]
    call printf
    mov  eax, 1
    jmp _label9
_label7:
    xor  r9d, r9d
    mov  r8d, dword [rsp+24h]
    mov  rdx, qword [rsp+28h]
    mov  ecx, 69h
    call NtQuerySystemInformation
    mov  dword [rsp+20h], eax
    cmp  dword [rsp+20h], 0          ; checking STATUS_SUCCESS
    jge  _label8
    mov  ecx, dword [rsp+20h]
    call getlasterror
    mov  rcx, qword [rsp+28h]
    call free                        ; do not forget release allocated memory block
    mov  eax, 1                      ; before leave (return 1)
    jmp  _label9
_label8:
    mov  rdx, qword [rsp+28h]
    lea  rcx, [rel fmt]
    call printf                      ; show CPU brand string
    mov  rcx, qword [rsp+28h]
    call free                        ; all done, release allocate memory block
    xor  eax, eax
_label9:
    add  rsp, 38h
    ret
