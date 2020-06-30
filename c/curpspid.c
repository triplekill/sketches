// requires clang instead cl (C4235)
#include <stdio.h>

unsigned long _GetCurrentProcessId(void) {
  unsigned long pid = 0;
  __asm {
#ifdef _M_X64
    mov rax, qword ptr gs:[30h]
    mov eax, dword ptr ds:[rax+40h]
#else
    mov eax, dword ptr fs:[18h]
    mov eax, dword ptr ds:[eax+20h]
#endif
    mov pid, eax
  }

  return pid;
}

int main(void) {
  printf("%lu\n", _GetCurrentProcessId());

  return 0;
}
