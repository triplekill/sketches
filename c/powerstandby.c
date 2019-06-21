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

#define LastWakeTime  0x0E
#define LastSleepTime 0x0F
#define Length(x) ((sizeof(x)) / (sizeof(x[0])))
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)
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

/*
NTSYSCALLAPI
NTSTATUS
NTAPI
NtPowerInformation(
   _In_ POWER_INFORMATION_LEVEL InformationLevel,
   _In_reads_bytes_opt_(InputBufferLength) PVOID InputBuffer,
   _IN_ ULONG InputBufferLength,
   _Out_writes_bytes_opt_(OutputBufferLength) PVOID OutputBuffer,
   _In_ ULONG OutputBufferLength
);

NTSYSAPI
VOID
NTAPI
RtlTimeToElapsedTimeFields(
   _In_ PLARGE_INTEGER Time,
   _Out_ PTIME_FIELDS Timefields
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);
*/

typedef NTSTATUS (__stdcall *pNtPowerInformation)(ULONG, PVOID, ULONG, PVOID, ULONG);
typedef VOID     (__stdcall *pRtlTimeToElapsedTimeFields)(PLARGE_INTEGER, PTIME_FIELDS);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
//////////////////////////////////////////////////////////////////////////////////////
pNtPowerInformation NtPowerInformation;
pRtlTimeToElapsedTimeFields RtlTimeToElapsedTimeFields;
pRtlNtStatusToDosError RtlNtStatusToDosError;
//////////////////////////////////////////////////////////////////////////////////////
void PrintErrMessage(NTSTATUS nts) {
  WCHAR msg[0x100];
  wprintf(L"%s\n", !FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
    FORMAT_MESSAGE_MAX_WIDTH_MASK, NULL,
    0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), msg, Length(msg), NULL
  ) ? L"Uknown error has been occured." : msg);
}

BOOLEAN LocateSignatures(void) {
  NtPowerInformation = AddrToFunc(pNtPowerInformation);
  if (!NtPowerInformation) return FALSE;

  RtlTimeToElapsedTimeFields = AddrToFunc(pRtlTimeToElapsedTimeFields);
  if (!RtlTimeToElapsedTimeFields) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (!RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

BOOLEAN GetTimeStamp(ULONG kind, ULONGLONG *value) {
  NTSTATUS nts = NtPowerInformation(kind, NULL, 0, value, sizeof(ULONGLONG));
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return FALSE;
  }

  return TRUE;
}

void PrintElapsedTime(WCHAR *desc, ULONGLONG value, BOOLEAN day) {
  TIME_FIELDS tf = {0};
  RtlTimeToElapsedTimeFields((PLARGE_INTEGER)&value, &tf);
  day ? wprintf(L"%-16s: %hu.%02hu:%02hu:%02hu\n",
    desc, tf.Day, tf.Hour, tf.Minute, tf.Second
  ) : wprintf(L"%-16s: %02hu:%02hu:%02hu\n", desc, tf.Hour, tf.Minute, tf.Second);
}

int wmain(void) {
  ULONGLONG wt = 0, st = 0;

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  if (!GetTimeStamp(LastWakeTime, &wt)
    || !GetTimeStamp(LastSleepTime, &st)) return 1;
  PrintElapsedTime(L"Suspended at", st, FALSE);
  PrintElapsedTime(L"Awaked at", wt, FALSE);
  PrintElapsedTime(L"Totally standby", wt - st, TRUE);

  return 0;
}
