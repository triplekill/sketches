#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <stdio.h>

PPEB GetPEB(void) {
  PVOID ptr = NULL;
  __asm {
#ifdef _M_X64 // C4235 (MSVC), use alternative compiler such as clang
    mov rax, qword ptr gs:[0x60]
    mov ptr, rax
#else
    mov eax, fs:[0x30]
    mov ptr, eax
#endif
  }

  return (PPEB)ptr;
}

int wmain(void) {
  PPEB peb = GetPEB();
  wprintf(L"Debugger present: %s\n", peb->BeingDebugged ? L"true" : L"false");

  return 0;
}
