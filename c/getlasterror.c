#ifdef _MSC_VER
#include <intrin.h>
#endif
#include <stdio.h>

typedef unsigned long DWORD;

DWORD _GetLastError(void) {
  DWORD e;
#ifdef __clang__
  __asm {
  #ifdef _WIN64
    mov rax, qword ptr gs:[0x30]
    mov eax, dword ptr [rax+0x68]
  #else
    mov eax, dword ptr fs:[0x18]
    mov eax, dword ptr [eax+0x34]
  #endif
    mov e, eax
  }
#elif _MSC_VER
  #ifdef _WIN64
    e = *(DWORD *)(__readgsqword(0x30) + 0x68);
  #else
    e = *(DWORD *)(__readfsdword(0x18) + 0x34);
  #endif
#endif
  return e;
}

int main(void) {
  printf("%lu\n", _GetLastError());
  return 0;
}
