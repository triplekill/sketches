#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <wchar.h>
#include <locale.h>
//////////////////////////////////////////////////////////////////////////////////////
typedef LONG  NTSTATUS;
typedef SHORT   CSHORT;
//////////////////////////////////////////////////////////////////////////////////////
#define SystemTimeOfDayInformation 3
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)
#define Length(ARRAY) ((sizeof(ARRAY)) / (sizeof(ARRAY[0])))
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))
//////////////////////////////////////////////////////////////////////////////////////
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

typedef struct _SYSTEM_TIMEOFDAY_INFORMATION {
   LARGE_INTEGER BootTime;
   LARGE_INTEGER CurrentTime;
   LARGE_INTEGER TimeZoneBias;
   ULONG         TimeZoneId;
   ULONG         Reserved;
   ULONGLONG     BootTimeBias;
   ULONGLONG     SleepTimeBias;
} SYSTEM_TIMEOFDAY_INFORMATION, *PSYSTEM_TIMEOFDAY_INFORMATION;

/*
NTSYSCALLAPI
NTSTATUS
NTAPI
NtQuerySystemInformation(
   _In_ SYSTEM_INFORMATION_CLASS SystemInformationClass,
   _Out_write_bytes_opt_(SystemInformationLLength) PVOID SystemInformation,
   _In_ ULONG SystemInformationLLength,
   _Out_opt_ PULONG ReturnLength
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);

NTSYSAPI
VOID
NTAPI
RtlTimeElapsedTimeFields(
   _In_ PLARGE_INTEGER Time,
   _Out_ PTIME_FIELDS TimeFields
);
*/

typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
typedef VOID     (__stdcall *pRtlTimeToElapsedTimeFields)(PLARGE_INTEGER, PTIME_FIELDS);
//////////////////////////////////////////////////////////////////////////////////////
pNtQuerySystemInformation NtQuerySystemInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;
pRtlTimeToElapsedTimeFields RtlTimeElapsedTimeFields;
//////////////////////////////////////////////////////////////////////////////////////
void PrintErrMessage(NTSTATUS nts) {
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

  RtlTimeElapsedTimeFields = AddrToFunc(pRtlTimeToElapsedTimeFields);
  if (!RtlTimeElapsedTimeFields) return FALSE;

  return TRUE;
}

int wmain(void) {
  NTSTATUS nts;
  LONGLONG delta;
  TIME_FIELDS tf = {0};
  SYSTEM_TIMEOFDAY_INFORMATION sti = {0};

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  nts = NtQuerySystemInformation(SystemTimeOfDayInformation, &sti, sizeof(sti), NULL);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

  delta = sti.CurrentTime.QuadPart - sti.BootTime.QuadPart;
  RtlTimeElapsedTimeFields((PLARGE_INTEGER)&delta, &tf);
  wprintf(L"%hu.%.2hu:%.2hu:%.2hu\n", tf.Day, tf.Hour, tf.Minute, tf.Second);

  return 0;
}
