#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <string>
#include <cwchar>
#include <vector>
#include <memory>
#include <locale>

typedef LONG NTSTATUS;

#define ProcessSessionInformation 24
#define NT_SUCCESS(Status) (static_cast<NTSTATUS>(Status) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))
typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PVOID);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryInformationProcess NtQueryInformationProcess;
pRtlNtStatusToDosError RtlNtStatusToDosError;

typedef struct _PROCESS_SESSION_INFORMATION {
   ULONG SessionId;
} PROCESS_SESSION_INFORMATION, *PPROCESS_SESSION_INFORMATION;

BOOLEAN LocateSignatures(void) {
  NtQueryInformationProcess = AddrToFunc(pNtQueryInformationProcess);
  if (nullptr == NtQueryInformationProcess) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(int argc, wchar_t **argv) {
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

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  if (2 != argc) {
    wstring app(argv[0]);
    wcout << L"Usage: " << app.substr(
      app.find_last_of(L"\\") + 1, app.length()
    ) << L" <PID>" << endl;
    return 1;
  }

  ULONG pid = wcstoul(argv[1], 0, 0);
  if (ERANGE == errno) {
    wcout << L"[!] invalid PID diapason." << endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
    PROCESS_QUERY_INFORMATION, FALSE, pid
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

  PROCESS_SESSION_INFORMATION psi = {0};
  NTSTATUS nts = NtQueryInformationProcess(
    *ps, ProcessSessionInformation, &psi, sizeof(psi), nullptr
  );
  if (!NT_SUCCESS(nts)) {
    getlasterror(0L);
    return 1;
  }
  wcout << L"PID: " << pid << L" | Session Id: " << psi.SessionId << endl;

  return 0;
}
