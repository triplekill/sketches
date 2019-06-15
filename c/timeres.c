#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <windows.h>
#include <stdio.h>
#include <locale.h>
//////////////////////////////////////////////////////////////////////////////////////
typedef LONG NTSTATUS;

#define CreateArray(x) L#x,
#define Length(x) ((sizeof(x)) / (sizeof(x[0])))
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)
#define FromTimerNames(x) x(Maximum) x(Minimum) x(Current)
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))

/*
NTSYSCALAPI
NTSTATUS
NTAPI
NtQueryTimerResolution(
   _Out_ PULONG MaximumResolution,
   _Out_ PULONG MinimumResolution,
   _Out_ PULONG CurrentResolution
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);
*/

typedef NTSTATUS (__stdcall *pNtQueryTimerResolution)(PULONG, PULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
//////////////////////////////////////////////////////////////////////////////////////
pNtQueryTimerResolution NtQueryTimerResolution;
pRtlNtStatusToDosError  RtlNtStatusToDosError;
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
  NtQueryTimerResolution = AddrToFunc(pNtQueryTimerResolution);
  if (!NtQueryTimerResolution) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (!RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(void) {
  int i;
  NTSTATUS nts;
  ULONG tr[3] = {0};
  const WCHAR *tn[] = { FromTimerNames(CreateArray) };

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  nts = NtQueryTimerResolution(&tr[0], &tr[1], &tr[2]);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

  for (i = 0; i < Length(tr); i++) {
    wprintf(L"%s timer resolution: %.3f ms\n", tn[i], (FLOAT)tr[i] / 10000);
  }

  return 0;
}
