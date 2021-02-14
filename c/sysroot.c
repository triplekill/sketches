#ifndef UNICODE
  #define UNICODE
#endif

#include <stdio.h>

int wmain(void) {
  wprintf(L"System root: %s\n", (wchar_t (*)[260])0x7FFE0030);

  return 0;
}
/*
#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>

#pragma comment(lib, "ntdll")

NTSYSAPI
PWSTR
NTAPI
RtlGetNtSystemRoot(
   VOID
);

int wmain(void) {
  wprintf(L"System root: %s\n", RtlGetNtSystemRoot());

  return 0;
}
*/
