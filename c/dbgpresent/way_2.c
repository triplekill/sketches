#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>

int wmain(void) {
  wprintf(L"Debugger present: %s\n", IsDebuggerPresent() ? L"true" : L"false");

  return 0;
}
