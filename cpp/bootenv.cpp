#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <objbase.h>
#include <iostream>
#include <vector>
#include <locale>

#pragma comment(lib, "ole32.lib")

typedef LONG NTSTATUS;

#define CreateArray(S) L#S,
#define SystemBootEnvironmetInformation 90
#define FirmwareType(T) T(Unknown) T(BIOS) T(UEFI) T(Max)
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>( \
                        GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef struct _SYSTEM_BOOT_ENVIRONMENT_INFORMATION {
   GUID BootIdentifier;
   FIRMWARE_TYPE FirmwareTime;
   union {
      ULONGLONG BootFlags;
      struct {
         ULONGLONG DbgMenuOsSelection : 1;
         ULONGLONG DbgHiberBoot : 1;
         ULONGLONG DbgSoftBoot : 1;
         ULONGLONG DbgMeasuredLaunch : 1;
         ULONGLONG DbgMeasuredLaunchCapable : 1;
         ULONGLONG DbgSystemHiveReplace: 1;
         ULONGLONG DbgMeasuredLaunchSmmProtections : 1;
      } dbg;
   } u;
} SYSTEM_BOOT_ENVIRONMENT_INFORMATION, *PSYSTEM_BOOT_ENVIRONMENT_INFORMATION;

typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQuerySystemInformation NtQuerySystemInformation;
pRtlNtStatusToDosError    RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  NtQuerySystemInformation = AddrToFunc(pNtQuerySystemInformation);
  if (nullptr == NtQuerySystemInformation) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(void) {
  using namespace std;
  locale::global(locale(""));

  auto getlasterror = [](NTSTATUS nts) {
    vector<wchar_t> msg(0x100);
    DWORD sz = static_cast<DWORD>(msg.size());
    wcout << (!FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
      FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr,
      0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &msg[0], sz, nullptr
    ) ? L"Unknown error has been occured." : &msg[0]) << endl;
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  SYSTEM_BOOT_ENVIRONMENT_INFORMATION sbei = {0};
  NTSTATUS nts = NtQuerySystemInformation(
    SystemBootEnvironmetInformation, &sbei, sizeof(sbei), nullptr
  );
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  const wchar_t *ft[] = {FirmwareType(CreateArray)};
  wchar_t guid[40] = {0}; // GUID to string

  if (StringFromGUID2(sbei.BootIdentifier, guid, 40))
    wcout << L"Boot identifier : " << guid << endl;
  wcout << L"Firmware type   : " << ft[sbei.FirmwareTime] << endl;

  return 0;
}
