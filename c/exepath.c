#include <stdio.h>

#ifdef _MSC_VER
#include <intrin.h>

typedef unsigned char byte;
#endif

wchar_t *GetExeFullPath(void) {
  wchar_t **path = NULL;
#ifdef __clang__
  __asm {
  #ifdef _WIN64
    mov rax, qword ptr gs:[0x60] ; PPEB
    mov rax, [rax+0x20]          ; PPEB->ProcessParameters
    mov rax, [rax+0x68]          ; PPEB->ProcessParameters->ImagePathName
    mov path, rax
  #else
    mov eax, dword ptr fs:[0x30]
    mov eax, [eax+0x10]
    mov eax, [eax+0x3C]
    mov path, eax
  #endif
  }
  return (wchar_t *)path;
#elif _MSC_VER
  void *exe = NULL;
  #ifdef _WIN64
    exe = *(void **)((byte *)__readgsqword(0x60) + 0x20);
    return *(wchar_t **)((byte *)exe + 0x68);
  #else
    exe = *(void **)((byte *)__readfsdword(0x30) + 0x10);
    return *(wchar_t **)((byte *)exe + 0x3C);
  #endif
#endif
}

int main(void) {
  printf("%ws\n", GetExeFullPath());
  return 0;
}
