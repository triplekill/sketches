#ifdef _MSC_VER
#include <intrin.h>
#endif
#include <stdio.h>

typedef void *PVOID;
typedef PVOID HANDLE;

HANDLE GetCurProcessHeap(void) {
  HANDLE h = NULL;
#ifdef __clang__
  __asm {
  #ifdef _M_X64
    mov rax, qword ptr gs:[0x60]
    mov rax, qword ptr [rax+0x30]
    mov h, rax
  #else
    mov eax, dword ptr fs:[0x30]
    mov eax, dword ptr [eax+0x18]
    mov h, eax
  #endif
  }
#elif _MSC_VER
  #ifdef _M_X64
    h = *(HANDLE *)(__readgsqword(0x60) + 0x30);
  #else
    h = *(HANDLE *)(__readfsdword(0x30) + 0x18);
  #endif
#endif
  return h;
}

int main(void) {
  printf("%p\n", GetCurProcessHeap());
  return 0;
}
