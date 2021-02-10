#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <stdio.h>
#include <locale.h>

#pragma comment(lib, "ntdll.lib")

typedef LONG NTSTATUS;

#define CreateArray(x) L#x,
#define Length(x) ((sizeof(x) / (sizeof(x[0]))))
#define FromTimeNames(x) x(Maximum) x(Minimum) x(Current)

void getlasterror(NTSTATUS nts) {
  HLOCAL msg = NULL;
  DWORD size = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    NULL, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&msg, 0, NULL
  );

  wprintf(L"[!] %.*s\n", (INT)(size - sizeof(WCHAR)), (LPWSTR)msg);

  if (NULL != LocalFree(msg))
    wprintf(L"LocalFree (%lu) fatal error.\n", GetLastError());
}

int wmain(void) {
  INT i;
  NTSTATUS nts;
  ULONG tr[3] = {0};
  const WCHAR *tn[] = {FromTimeNames(CreateArray)};

  _wsetlocale(LC_CTYPE, L"");
  nts = NtQueryTimerResolution(&tr[0], &tr[1], &tr[2]);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  for (i = 0; i < Length(tr); i++) {
    wprintf(L"%s timer resolution: %.3f ms\n", tn[i], (FLOAT)tr[i] / 10000);
  }

  return 0;
}
