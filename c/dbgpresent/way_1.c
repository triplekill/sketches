#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>
#include <locale.h>

void PrintErrMessage(void) {
  HLOCAL msg = NULL;
  DWORD  len = FormatMessage(
     FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
     NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
     (LPWSTR)&msg, 0, NULL
  );
  wprintf(L"%s", (LPWSTR)msg);

  if (NULL != LocalFree(msg)) {
    wprintf(L"LocalFree fatal error.\n");
  }
}

int wmain(void) {
  _wsetlocale(LC_CTYPE, L"");
  BOOL dbg = FALSE;
  if (!CheckRemoteDebuggerPresent(GetCurrentProcess(), &dbg)) {
    PrintErrMessage();
    return 1;
  }
  wprintf(L"Debugger present: %s\n", dbg ? L"true" : L"false");

  return 0;
}
