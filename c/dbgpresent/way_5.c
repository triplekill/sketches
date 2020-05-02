#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <intrin.h>
#include <stdio.h>

int wmain(void) {
  PPEB peb = NULL;
#ifdef _M_X64
  peb = (PPEB)__readgsqword(0x60);
#else
  peb = (PPEB)__readfsdword(0x30);
#endif
  wprintf(L"Debugger present: %s\n", peb->BeingDebugged ? L"true" : L"false");

  return 0;
}
