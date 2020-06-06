// requires clang instead cl (C4235)
#include <stdio.h>

unsigned long GetCurrentLocale(void) {
  unsigned long *locale = NULL;
  __asm {
#ifdef _M_X64
    mov rax, qword ptr gs:[0x30] ; PTEB
    mov rax, [rax + 0x108]       ; PTEB->CurrentLocale
    mov locale, rax
#else
    mov eax, dword ptr fs:[0x18]
    mov eax, [eax + 0x0C4]
    mov locale, eax
#endif
  }

  return (unsigned long)locale;
}

int main(void) {
  printf("%#lx\n", GetCurrentLocale());
  return 0;
}
