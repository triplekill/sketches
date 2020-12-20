#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <iostream>
#include <string>
#include <cwchar>
#include <vector>
#include <memory>
#include <locale>

typedef LONG NTSTATUS;

#pragma comment (lib, "ntdll.lib")

#define ProcessWindowInformation (static_cast<PROCESSINFOCLASS>(50))
#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004))

typedef struct _PROCESS_WINDOW_INFORMATION {
   ULONG  WindowFlags;
   USHORT WindowTitleLength;
   WCHAR  WindowTitle[1];
} PROCESS_WINDOW_INFORMATION, *PPROCESS_WINDOW_INFORMATION;

int wmain(int argc, WCHAR **argv) {
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
      wcout << L"[!] LocalFree (" << GetLastError() << L") fatal error." << endl;
  };

  if (2 != argc) {
    wstring app(argv[0]);
    wcout << L"Usage: " << app.substr(
      app.find_last_of(L"\\") + 1, app.length()
    ) << L" <PID>" << endl;
    return 1;
  }

  ULONG pid = wcstoul(argv[1], 0, 0);
  if (ERANGE == errno) {
    wcout << L"[!] Invalid PID diapason." << endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
    PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid
  )), [&getlasterror](HANDLE *instance) {
    if (*instance) {
      if (!CloseHandle(*instance)) getlasterror(0L);
      else wcout << L"[*] resources have been successfully released" << endl;
    }
  });

  if (!*ps) {
    getlasterror(0L);
    return 1;
  }
  wcout << L"[*] the process (" << pid << L") is successfully opened" << endl;

  NTSTATUS nts = STATUS_INFO_LENGTH_MISMATCH;
  vector<PROCESS_WINDOW_INFORMATION> pwi(sizeof(PROCESS_WINDOW_INFORMATION));
  while (STATUS_INFO_LENGTH_MISMATCH == nts) {
    nts = NtQueryInformationProcess(
      *ps, ProcessWindowInformation, &pwi[0], pwi.size(), nullptr
    );
    pwi.resize(pwi.size() * 2);
  }

  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    vector<PROCESS_WINDOW_INFORMATION> ().swap(pwi);
    return 1;
  }

  wcout << pwi[0].WindowTitle << endl;
  vector<PROCESS_WINDOW_INFORMATION> ().swap(pwi);

  return 0;
}
