#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <locale.h>
//////////////////////////////////////////////////////////////////////////////////////
#define T(x) x,
  typedef enum _NT_PRODUCT_TYPE { NtProductTypes } NT_PRODUCT_TYPE, *PNT_PRODUCT_TYPE;
#undef T
#define T(x) L#x,
#define Length(x) ((sizeof(x)) / (sizeof(x[0])))
#define NtProductTypes T(WinNT) T(LanManNT) T(Server)
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))

/*
NTSYSAPI
BOOLEAN
NTAPI
RtlGetNtProductType(
   _Out_ PNT_PRODUCT_TYPE NtProductType
);

NTSYSAPI
VOID
NTAPI
RtlGetNtVersionNumbers(
   _Out_opt_ PULONG NtMajorVersion,
   _Out_opt_ PULONG NtMinorVersion,
   _Out_opt_ PULONG NtBuildNumber
);
*/
typedef BOOLEAN (__stdcall *pRtlGetNtProductType)(PNT_PRODUCT_TYPE);
typedef VOID    (__stdcall *pRtlGetNtVersionNumbers)(PULONG, PULONG, PULONG);
//////////////////////////////////////////////////////////////////////////////////////
pRtlGetNtProductType RtlGetNtProductType;
pRtlGetNtVersionNumbers RtlGetNtVersionNumbers;
//////////////////////////////////////////////////////////////////////////////////////
void PrintErrMessage(void) {
  WCHAR msg[0x100];
  wprintf(L"%s\n", !FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
    FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL, GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), msg, Length(msg), NULL
  ) ? L"Unknown error has been occured." : msg);
}

BOOLEAN LocateSignatures(void) {
  RtlGetNtProductType = AddrToFunc(pRtlGetNtProductType);
  if (!RtlGetNtProductType) return FALSE;

  RtlGetNtVersionNumbers = AddrToFunc(pRtlGetNtVersionNumbers);
  if (!RtlGetNtVersionNumbers) return FALSE;

  return TRUE;
}

int wmain(void) {
  NT_PRODUCT_TYPE ntpt;
  const WCHAR *pt[] = { NtProductTypes };
  ULONG major = 0, minor = 0, build = 0;

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessage();
    return 1;
  }

  if (RtlGetNtProductType(&ntpt)) wprintf(L"Type   : %s\n", pt[ntpt - 1]);
  RtlGetNtVersionNumbers(&major, &minor, &build);
  wprintf(L"Version: %u.%u.%u\n", major, minor, build & 0xFFFF);

  return 0;
}
