#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <locale.h>
//////////////////////////////////////////////////////////////////////////////////////
typedef LONG NTSTATUS;

#define T(x) L#x,
#define SystemPowerInformation 12
#define Length(x) ((sizeof(x)) / (sizeof(x[0])))
#define Modes T(Active) T(Passive) T(Invalid)
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))

typedef struct _SYSTEM_POWER_INFORMATION {
   ULONG MaxIdlenessAllowed;
   ULONG Idleness;
   ULONG TimeRemaining;
   UCHAR CoolingMode;
} SYSTEM_POWER_INFORMATION, *PSYSTEM_POWER_INFORMATION;

/*
NTSYSCALLAPI
NTSTATUS
NTAPI
NtPowerInformation(
   _In_ POWER_INFORMATION_LEVEL InformationLevel,
   _In_reads_bytes_opt_(InputBufferLength) PVOID InputBuffer,
   _In_ ULONG InputBufferLength,
   _Out_writes_bytes_opt_(OutputBufferLength) PVOID OutputBuffer,
   _In_ ULONG OutputBufferLength
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);
*/

typedef NTSTATUS (__stdcall *pNtPowerInformation)(ULONG, PVOID, ULONG, PVOID, ULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
//////////////////////////////////////////////////////////////////////////////////////
pNtPowerInformation NtPowerInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;
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
  NtPowerInformation = AddrToFunc(pNtPowerInformation);
  if (!NtPowerInformation) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (!RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(void) {
  NTSTATUS nts;
  const WCHAR  *modes[] = { Modes };
  SYSTEM_POWER_INFORMATION spi = {0};

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  nts = NtPowerInformation(
    SystemPowerInformation, NULL, 0, &spi, sizeof(SYSTEM_POWER_INFORMATION)
  );
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }
  wprintf(
    L"The system is currently in %s cooling mode.\n", modes[spi.CoolingMode]
  );

  return 0;
}
