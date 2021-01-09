#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>
#include <stddef.h>
#include <locale.h>

typedef LONG NTSTATUS;

#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)
#define AddrToFunc(T) ((T)(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef NTSTATUS (__stdcall *pNtPowerInformation)(POWER_INFORMATION_LEVEL, PVOID, ULONG, PVOID, ULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtPowerInformation NtPowerInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  NtPowerInformation = AddrToFunc(pNtPowerInformation);
  if (NULL == NtPowerInformation) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (NULL == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

void GetLastErrorMsg(NTSTATUS nts) {
  HLOCAL loc = NULL;
  DWORD size = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    NULL, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&loc, 0, NULL
  );

  if (0 == size)
    wprintf(L"[?] Unknown error has been occured.\n");
  else
    wprintf(L"[!] %.*s\n", (INT)(size - sizeof(WCHAR)), (LPWSTR)loc);

  if (NULL != LocalFree(loc))
    wprintf(L"LocalFree (%d) fatal error.\n", GetLastError());
}

int main(void) {
  NTSTATUS nts;
  SYSTEM_BATTERY_STATE sbi = {0};
  #define readf(F) wprintf(L"[+0x%.3zx] %s: %u\n", \
                                       (offsetof(SYSTEM_BATTERY_STATE, F)), (L#F), (sbi.F))
  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    GetLastErrorMsg(0L);
    return 1;
  }

  nts = NtPowerInformation(SystemBatteryState, NULL, 0, &sbi, sizeof(SYSTEM_BATTERY_STATE));
  if (!NT_SUCCESS(nts)) {
    GetLastErrorMsg(nts);
    return 1;
  }

  readf(AcOnLine);
  readf(BatteryPresent);
  readf(Charging);
  readf(Discharging);
  readf(Tag);
  readf(MaxCapacity);
  readf(RemainingCapacity);
  readf(Rate);
  readf(EstimatedTime);
  readf(DefaultAlert1);
  readf(DefaultAlert2);

  return 0;
}
