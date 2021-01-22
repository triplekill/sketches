/*
#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>
#include <locale.h>

#define Length(ARRAY) ((sizeof(ARRAY)) / (sizeof(ARRAY[0])))

#pragma comment(lib, "advapi32")

void PrintErrMessage(LSTATUS err) {
  WCHAR msg[0x100];
  wprintf(L"%s\n", !FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
    FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, err,
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), msg, Length(msg),
    NULL) ? L"Unknown error has been occured." : msg
  );
}

int wmain(void) {
  HKEY    rk;
  LSTATUS es;
  DWORD  len, lpe = 0;

  _wsetlocale(LC_CTYPE, L"");
  es = RegOpenKeyEx(
    HKEY_LOCAL_MACHINE,
    L"SYSTEM\\CurrentControlSet\\Control\\FileSystem",
    0, KEY_QUERY_VALUE, &rk
  );
  if (ERROR_SUCCESS != es) {
    PrintErrMessage(es);
    return 1;
  }

  es = RegQueryValueEx(
    rk, L"LongPathsEnabled", NULL, NULL, NULL, &len
  );

  if (ERROR_SUCCESS == es) {
    es = RegQueryValueEx(
      rk, L"LongPathsEnabled", NULL, NULL, (LPBYTE)&lpe, &len
    );
    if (ERROR_SUCCESS != es)
      PrintErrMessage(es);
    else
      wprintf(L"Is long paths enabled? %s\n", 0 == lpe ? L"false" : L"true");
  }

  es = RegCloseKey(rk);
  if (ERROR_SUCCESS != es) {
    wprintf(L"Fatal error: can not release registry key.\n");
  }

  return 0;
}
*/
/*
#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>
#include <locale.h>

#define Length(ARRAY) ((sizeof(ARRAY)) / (sizeof(ARRAY[0])))
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))

typedef BOOLEAN (__stdcall *pRtlAreLongPathsEnabled)(VOID);
pRtlAreLongPathsEnabled RtlAreLongPathsEnabled;

int wmain(void) {
  WCHAR msg[0x100];

  _wsetlocale(LC_CTYPE, L"");
  RtlAreLongPathsEnabled = AddrToFunc(pRtlAreLongPathsEnabled);
  if (!RtlAreLongPathsEnabled) {
    wprintf(L"%s\n", !FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
      FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), msg, Length(msg), NULL
      ) ? L"Unknown error has been occured." : msg
    );
    return 1;
  }
  wprintf(L"Is long paths enabled? %s\n",
    RtlAreLongPathsEnabled() ? L"true" : L"false"
  );

  return 0;
}
*/
#ifdef _MSC_VER
#include <intrin.h>
#endif
#include <stdio.h>

int main(void) {
  unsigned char status = 0;
#ifdef __clang__
  __asm {
  #ifdef _M_X64
    mov rax, qword ptr gs:[0x60]
    mov al, byte ptr [rax+3]
  #else
    mov eax, dword ptr fs:[0x30]
    mov al, byte ptr [eax+3]
  #endif
    shr al, 7
    mov status, al
  }
#elif _MSC_VER
  #ifdef _M_X64
    status = *(unsigned char *)(__readgsqword(0x60) + 3);
  #else
    status = *(unsigned char *)(__readfsdword(0x30) + 3);
  #endif
  status >>= 7;
#endif
  printf("Is long paths enabled? %s\n", 0 != status ? "true" : "false");
  return 0;
}
