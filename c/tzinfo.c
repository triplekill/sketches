/*
*
* See
*     HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation
*
*/
#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <locale.h>
//////////////////////////////////////////////////////////////////////////////////////
typedef LONG  NTSTATUS;
typedef SHORT   CSHORT;

#define SystemCurrentTimeZoneInformation 44
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)
#define Length(ARRAY) ((sizeof(ARRAY)) / (sizeof(ARRAY[0])))
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))

typedef struct _TIME_FIELDS {
   CSHORT Year;
   CSHORT Month;
   CSHORT Day;
   CSHORT Hour;
   CSHORT Minute;
   CSHORT Second;
   CSHORT Milliseconds;
   CSHORT Weekday;
} TIME_FIELDS, *PTIME_FIELDS;

typedef struct _RTL_TIME_ZONE_INFORMATION {
   LONG        Bias;
   WCHAR       StandardName[32];
   TIME_FIELDS StandardStart;
   LONG        StandardBias;
   WCHAR       DalightName[32];
   TIME_FIELDS DalightStart;
   LONG        DalightBias;
} RTL_TIME_ZONE_INFORMATION, *PRTL_TIME_ZONE_INFORMATION;

typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
//////////////////////////////////////////////////////////////////////////////////////
pNtQuerySystemInformation NtQuerySystemInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;
//////////////////////////////////////////////////////////////////////////////////////
void PrintErrMessge(NTSTATUS nts) {
  WCHAR msg[0x100];
  wprintf(L"%s\n", !FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
    FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL,
    0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), msg, Length(msg), NULL
  ) ? L"Unknown error has been occured." : msg);
}

BOOLEAN LocateSignatures(void) {
  NtQuerySystemInformation = AddrToFunc(pNtQuerySystemInformation);
  if (!NtQuerySystemInformation) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (!RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(void) {
  NTSTATUS nts;
  RTL_TIME_ZONE_INFORMATION tz = {0};

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessge(0L);
    return 1;
  }

  nts = NtQuerySystemInformation(SystemCurrentTimeZoneInformation, &tz, sizeof(tz), NULL);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessge(nts);
    return 1;
  }

  wprintf(L"Bias: %#18x\nDalightBias: %#11x\nDalightName: %17s\nStandardName: %s\n",
    tz.Bias, tz.DalightBias, tz.DalightName, tz.StandardName
  );

  return 0;
}
