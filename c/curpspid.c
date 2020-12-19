#include <stdio.h>
#include <intrin.h>

unsigned long _GetCurrentProcessId(void) {
  unsigned long pid = 0;
#ifdef __clang__
  __asm {
  #ifdef _M_X64
    mov rax, qword ptr gs:[30h]
    mov eax, dword ptr ds:[rax+40h]
  #else
    mov rax, dword ptr fs:[18h]
    mov eax, dword ptr ds:[eax+20h]
  #endif
    mov pid, eax
  }
#elif _MSC_VER
  #ifdef _M_X64
    pid = *(unsigned long *)(__readgsqword(0x30) + 0x40);
  #else
    pid = *(unsigned long *)(__readfsdword(0x18) + 0x20);
  #endif
#endif
  return pid;
}

int main(void) {
  printf("%lu\n", _GetCurrentProcessId());
  return 0;
}
