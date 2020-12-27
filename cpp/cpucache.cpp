#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <locale>

typedef LONG NTSTATUS;

#pragma comment (lib, "ntdll.lib")

#define T(x) L#x,
#define CacheType T(Unified) T(Instruction) T(Data) T(Trace)
#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004L))
#define SystemLogicalProcessorInformation (static_cast<SYSTEM_INFORMATION_CLASS>(73))

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
      wcout << L"[?] Unknown error has been occured." << endl;
    else {
      wstring msg(reinterpret_cast<LPWSTR>(loc));
      wcout << L"[!] " << msg.substr(0, size - sizeof(WCHAR)) << endl;
    }

    if (nullptr != LocalFree(loc))
      wcout << L"LocalFree (" << GetLastError() << L") fatal error." << endl;
  };

  ULONG buf_len = 0;
  NTSTATUS nts = NtQuerySystemInformation(SystemLogicalProcessorInformation, nullptr, 0, &buf_len);
  if (STATUS_INFO_LENGTH_MISMATCH != nts) {
    getlasterror(nts);
    return 1;
  }

  vector<SYSTEM_LOGICAL_PROCESSOR_INFORMATION> buf(buf_len);
  nts = NtQuerySystemInformation(SystemLogicalProcessorInformation, &buf[0], buf_len, nullptr);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }
  ULONG total = buf_len / sizeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION);
  const WCHAR *cache[] = { CacheType };
  for (ULONG i = 0; i < total; i++) {
    if (2 != buf[i].Relationship) continue;
    wcout  << setw(11) << cache[buf[i].Cache.Type]
           << L" L" << buf[i].Cache.Level << L": " << setw(4)
           << buf[i].Cache.Size / 1024 << L" KB, Assoc: " << setw(2)
           << buf[i].Cache.Associativity << L", LineSize: "
           << buf[i].Cache.LineSize << endl;
  }

  return 0;
}
