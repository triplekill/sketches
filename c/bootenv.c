#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>
#include <locale.h>

typedef LONG NTSTATUS;

#define S(x) L#x,
#define Env S(Unknown) S(BIOS) S(UEFI) S(MAX)
#define Length(x) ((sizeof(x)) / (sizeof(x[0])))
#define AddrToFunc(DLL, T) ((T)(GetProcAddress( \
                  GetModuleHandle(DLL), (&((#T)[1])))))
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)

typedef struct _SYSTEM_BOOT_ENVIRONMENT_INFORMATION {
   GUID BootIdentifier;
   FIRMWARE_TYPE FirmwareType;
   union {
     ULONGLONG BootFlags;
     struct {
        ULONGLONG DbgMenuOsSelection : 1;
        ULONGLONG DbgHiberBoot : 1;
        ULONGLONG DbgSoftBoot : 1;
        ULONGLONG DbgMeasuredLaunch : 1;
        ULONGLONG DbgMeasuredLaunchCapable : 1;
        ULONGLONG DbgSystemHiveReplace : 1;
        ULONGLONG DbgMeasuredLaunchSmmProtections : 1;
     };
   };
} SYSTEM_BOOT_ENVIRONMENT_INFORMATION,
*PSYSTEM_BOOT_ENVIRONMENT_INFORMATION;

typedef BOOL (__stdcall *pGetFirmwareType)(PFIRMWARE_TYPE);
typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef ULONG (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

// the definition of this function is already exists in the latest Windows SDK
pGetFirmwareType _GetFirmwareType; // so, check if present (on early versions)
pNtQuerySystemInformation NtQuerySystemInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;

void PrintErrMessage(NTSTATUS nts) {
  HLOCAL msg = NULL;
  DWORD  len = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, NULL,
    0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&msg, 0, NULL
  );
  if (0 != len)
    wprintf(L"%.*s\n", len - 1, (LPWSTR)msg);
  else
    wprintf(L"Unknown error has been occured.\n");
  if (NULL != LocalFree(msg))
    wprintf(L"Fatal error: resource has not been released.\n");
}

int wmain(void) {
  _wsetlocale(LC_CTYPE, L"");
  _GetFirmwareType = AddrToFunc(L"kernel32", pGetFirmwareType);
  if (NULL == _GetFirmwareType) {
    PrintErrMessage(0L);
    return 1;
  }
  // first variant
  FIRMWARE_TYPE ft;
  const WCHAR *env[] = { Env };
  if (!_GetFirmwareType(&ft)) {
    PrintErrMessage(0L);
    return 1;
  }
  wprintf(L"%s (GetFirmwareType)\n", env[ft]);
  // second variant
  NtQuerySystemInformation = AddrToFunc(L"ntdll.dll", pNtQuerySystemInformation);
  if (NULL == NtQuerySystemInformation) { // really?!
    PrintErrMessage(0L);
    return 1;
  }
  RtlNtStatusToDosError = AddrToFunc(L"ntdll.dll", pRtlNtStatusToDosError);
  if (NULL == RtlNtStatusToDosError) { // is it joke too?
    PrintErrMessage(0L);
    return 1;
  }
  SYSTEM_BOOT_ENVIRONMENT_INFORMATION bei = {0};
  NTSTATUS nts = NtQuerySystemInformation(90, &bei, sizeof(bei), NULL);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }
  wprintf(L"%s (NtQuerySystemInformation)\n", env[bei.FirmwareType]);
  // third variant
  WCHAR buf[32];
  DWORD ret = GetEnvironmentVariable(L"FIRMWARE_TYPE", buf, Length(buf));
  if (0 == ret) {
    PrintErrMessage(0L);
    return 1;
  }
  wprintf(L"%s (GetEnvironmentVariable)\n", buf);

  return 0;
}
