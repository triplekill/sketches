; locates kernel32.dll base address
; requires legacy_stdio_definitions.lib while linking
global main
extern printf

section .data
fmt: db "%p", 0xA, 0

section .text
main:
    push r15            ; usage not clobber registers seems
    push r12            ; so hacky (requires releasing)
    sub  rsp, 38h       ; reserve stack
    mov  r12, [gs:60h]  ; PPEB
    mov  r12, [r12+18h] ; PPEB->Ldr
    mov  r12, [r12+20h] ; PPEB->Ldr->InMemoryOrderModuleList
    mov  r12, [r12]     ; skip first entry (this app)
    mov  r15, [r12+20h] ; ntdll
    mov  r12, [r12]     ; skip second entry (ntdll)
    mov  r12, [r12+20h] ; kernel32
    lea  rcx, [rel fmt] ; loading effective address
    mov  rdx, r12
    call printf
    add  rsp, 38h       ; releasing
    pop  r12
    pop  r15
    ret
