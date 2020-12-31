#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <iostream>
#include <string>
#include <vector>
#include <locale>

typedef LONG NTSTATUS;

#pragma comment (lib, "ntdll.lib")

#define ProcessHandleTable (static_cast<PROCESSINFOCLASS>(58))
#define NtCurrentProcess() (reinterpret_cast<HANDLE>(static_cast<LONG_PTR>(-1)))

int wmain(void) {
  using namespace std;

  locale::global(locale(""));
  auto getlasterror = [](NTSTATUS nts) {
    HLOCAL loc{};
    DWORD size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, RtlNtStatusToDosError(nts),
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

  vector<ULONG> buf(0x400);
  NTSTATUS nts = NtQueryInformationProcess(
    NtCurrentProcess(), ProcessHandleTable, &buf[0], buf.size(), nullptr
  );
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }
  for (const auto val : buf) {
    if (0 == val) break;
    wcout << hex << val << endl;
  }

  return 0;
}
