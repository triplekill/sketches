#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <cstdio>
#include <vector>
#include <locale>

#pragma comment (lib, "ntdll.lib")

#define Mb (0x100000L)
#define STATUS_BUFFER_TOO_SMALL (static_cast<NTSTATUS>(0xC0000023L))

extern "C" {
  NTSYSAPI
  ULONG
  NTAPI RtlNtStatusToDosError(
     _In_ NTSTATUS Status
  );

  NTSYSCALLAPI
  NTSTATUS
  NTAPI NtPowerInformation(
     _In_ POWER_INFORMATION_LEVEL InformationLevel,
     _In_reads_bytes_opt_(InputBufferLength) PVOID InputBuffer,
     _In_ ULONG InputBufferLength,
     _Out_writes_bytes_opt_(OutputBufferLength) PVOID OutputBuffer,
     _In_ ULONG OutputBufferLength
  );

  typedef struct _SYSTEM_HIBERFILE_INFORMATION {
     ULONG NumberOfMcbPairs;
     LARGE_INTEGER Mcb[1];
  } SYSTEM_HIBERFILE_INFORMATION, *PSYSTEM_HIBERFILE_INFORMATION;
}

int wmain(void) {
  using namespace std;
  locale::global(locale(""));

  auto getlasterror = [](NTSTATUS nts) {
    HLOCAL msg{};
    DWORD size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&msg), 0, nullptr
    );

    if (!size)
      wprintf(L"[?] Unknown error has been occured.\n");
    else
      wprintf(L"[!] %.*s\n", static_cast<INT>(size - sizeof(WCHAR)),
                             reinterpret_cast<LPWSTR>(msg));

    if (nullptr != LocalFree(msg))
      wprintf(L"[!] LocalFree (%d) fatal error.\n", GetLastError());
  };

  NTSTATUS nts = STATUS_BUFFER_TOO_SMALL;
  vector<BYTE> buf(sizeof(SYSTEM_HIBERFILE_INFORMATION));
  while (1) {
    nts = NtPowerInformation(SystemHiberFileInformation, nullptr, 0, &buf[0], buf.size());
    if (STATUS_BUFFER_TOO_SMALL != nts) break;
    buf.resize(buf.size() * 2);
  }

  auto hi = reinterpret_cast<PSYSTEM_HIBERFILE_INFORMATION>(&buf[0]);
  wprintf(L"Mcb pairs: %lu\n", hi->NumberOfMcbPairs);
  for (int i = 0; i < hi->NumberOfMcbPairs; i++) {
    wprintf(L"  No.%d type: %7s sz: %5I64d Mb\n", i + 1,
                                              !hi->Mcb[i].HighPart ? L"reduced" : L"full",
                                              hi->Mcb[i].QuadPart / Mb);
  }

  vector<BYTE> ().swap(buf);

  return 0;
}
