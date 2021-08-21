#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <cstdio>
#include <vector>
#include <locale>

#pragma comment(lib, "ntdll.lib")

#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004L))

int wmain(void) {
  using namespace std;
  locale::global(locale(""));

  auto getlasterror = [](NTSTATUS nts) {
    HLOCAL loc{};
    DWORD size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&loc), 0, nullptr
    );

    if (!size)
      wprintf(L"[?] Unknown error has been occured.\n");
    else
      wprintf(L"[!] %.*s\n", (INT)(size - sizeof(WCHAR)), reinterpret_cast<LPWSTR>(loc));

    if (nullptr != LocalFree(loc))
      wprintf(L"[!] LocalFree (%d) fatal error.\n", GetLastError());
  };

  ULONG req{};
  NTSTATUS nts = NtQuerySystemInformation(SystemProcessInformation, nullptr, 0, &req);
  if (STATUS_INFO_LENGTH_MISMATCH != nts) {
    getlasterror(nts);
    return 1;
  }

  vector<BYTE> buf(static_cast<SIZE_T>(req));
  nts = NtQuerySystemInformation(SystemProcessInformation, &buf[0], req, nullptr);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  PSYSTEM_PROCESS_INFORMATION ps = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(&buf[0]);
  wprintf(L"PID    PPID BP SI Name\n----- ----- -- -- -----\n");
  while (ps->NextEntryOffset) {
    wprintf(L"%5I64u %5I64u %2d %2d %s\n", reinterpret_cast<ULONGLONG>(ps->UniqueProcessId),
                                           reinterpret_cast<ULONGLONG>(ps->Reserved2),
                                           ps->BasePriority,
                                           ps->SessionId,
                                           ps->ImageName.Buffer);
    ps = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(reinterpret_cast<PBYTE>(ps) + ps->NextEntryOffset);
  }

  return 0;
}
