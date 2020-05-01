#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <stdio.h>
#include <locale.h>

#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))

typedef PPEB (__stdcall *pRtlGetCurrentPeb)(VOID);

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

  PPEB peb = NULL;
  pRtlGetCurrentPeb RtlGetCurrentPeb = AddrToFunc(pRtlGetCurrentPeb);
  if (NULL == RtlGetCurrentPeb) {
    PrintErrMessage();
    return 1;
  }
  peb = RtlGetCurrentPeb();
  wprintf(L"Debugger present: %s\n", peb->BeingDebugged ? L"true" : L"false");

  return 0;
}
