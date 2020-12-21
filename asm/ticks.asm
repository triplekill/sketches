global main
extern printf

section .data
fmt: db "%llu", 0xA, 0

section .text
main:
  sub  rsp, 38h                   ; reserve stack
  mov  rax, qword [abs 7FFE0320h] ; KUSER_SHARED_DATA->TickCountQuad
  mov  qword [rsp+28h], rax
  mov  eax, dword [abs 7FFE0004h] ; KUSER_SHARED_DATA->TickCountMultiplier
  mov  dword [rsp+20h], eax
  mov  eax, dword [rsp+20h]
  imul rax, qword [rsp+28h]
  shr  rax, 18h
  mov  rdx, rax
  lea  rcx, [rel fmt]
  call printf
  xor  eax, eax
  add  rsp, 38h
  ret
