#include <windows.h>
#include <winternl.h>
#include <intrin.h>
#include <stdio.h>

#define OverrideUnicodeString(p, s) {             \
  ((p).Length) = ((sizeof(s)) - (sizeof(WCHAR))); \
  ((p).MaximumLength) = (sizeof(s));              \
  ((p).Buffer) = s;                               \
};

int wmain(void) {
  PPEB  peb = NULL;
  WCHAR s[] = L"C:\\Windows\\system32\\notepad.exe";
#ifdef _M_X64
  peb = (PPEB)__readgsqword(0x60);
#else
  peb = (PPEB)__readfsdword(0x30);
#endif
  wprintf(L"Image path  : %s\nCommand line: %s\n",
     peb->ProcessParameters->ImagePathName.Buffer,
     peb->ProcessParameters->CommandLine.Buffer
  );
  OverrideUnicodeString(peb->ProcessParameters->ImagePathName, s);
  OverrideUnicodeString(peb->ProcessParameters->CommandLine, s);
  wprintf(L"Image path  : %s\nCommand line: %s\n",
    peb->ProcessParameters->ImagePathName.Buffer,
    peb->ProcessParameters->CommandLine.Buffer
  );

  return 0;
}
