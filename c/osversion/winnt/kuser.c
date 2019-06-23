#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
//////////////////////////////////////////////////////////////////////////////////////
#define T(x) L#x,
#define NtMajorVersion 0x26C
#define NtMinorVersion 0x270
#define NtBuildNumber  0x260
#define NtProductType  0x264
#define KUSER(x) (*((unsigned long *)(0x7FFE0000 + (x))))
#define NtProductTypes T(WinNT) T(LanManNT) T(Server)
//////////////////////////////////////////////////////////////////////////////////////
int wmain(void) {
  const wchar_t *pt[] = { NtProductTypes };
  wprintf(L"Type   : %s\nVersion: %u.%u.%u\n",
    pt[KUSER(NtProductType) - 1], KUSER(NtMajorVersion),
    KUSER(NtMinorVersion), KUSER(NtBuildNumber)
  );

  return 0;
}
