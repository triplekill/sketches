#ifndef UNICODE
  #define UNICODE
#endif

#include <intrin.h>
#include <stdio.h>

typedef unsigned char byte;

int main(void) {
  void *env;
  size_t sz;
#ifdef _M_X64
  env = *(void **)((byte *)__readgsqword(0x60) + 0x20);
  sz = *(size_t *)((byte *)env + 0x3F0);
  env = *(void **)((byte *)env + 0x80);
#else
  env = *(void **)((byte *)__readfsdword(0x30) + 0x10);
  sz = *(size_t *)((byte *)env + 0x290);
  env = *(void **)((byte *)env + 0x48);
#endif
  for (int i = 0; i < sz / sizeof(wchar_t); i++) {
    wchar_t c = *(wchar_t *)env;
    printf("%wc", L'\0' != c ? c : L'\n');
    ((wchar_t *)env)++;
  }

  return 0;
}
