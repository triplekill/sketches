#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <string>
#include <memory>
#include <locale>

typedef LONG NTSTATUS;

#define SeDebugPrivilege 20
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef NTSTATUS (__stdcall *pRtlAdjustPrivilege)(ULONG, BOOLEAN, BOOLEAN, PBOOLEAN);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pRtlAdjustPrivilege RtlAdjustPrivilege;
pRtlNtStatusToDosError RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  RtlAdjustPrivilege = AddrToFunc(pRtlAdjustPrivilege);
  if (nullptr == RtlAdjustPrivilege) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

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
      wcout << L"LocalFree (" << GetLastError() << L") fatal error." << endl;
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  BOOLEAN state{};
  NTSTATUS nts = RtlAdjustPrivilege(SeDebugPrivilege, TRUE, FALSE, &state);
  if (!NT_SUCCESS(nts)) { // because administrator rights are required
    getlasterror(nts);
    return 1;
  }

  if (3 != argc) {
    wstring app(argv[0]);
    wcout << L"Usage: "
          << app.substr(app.find_last_of(L"\\") + 1, app.length())
          << L" <PID> <app>" << endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
    PROCESS_ALL_ACCESS, FALSE, wcstoul(argv[1], 0, 0)
  )), [&getlasterror](HANDLE *instance) {
    if (*instance) {
      if (!CloseHandle(*instance)) getlasterror(0L);
      else wcout << L"[*] done" << endl;
    }
  });

  if (!*ps) {
    getlasterror(0L);
    return 1;
  }

  SIZE_T sz = 0;
  if (!InitializeProcThreadAttributeList(nullptr, 1, 0, &sz) && 0 == sz) {
    getlasterror(0L);
    return 1;
  }

  PPROC_THREAD_ATTRIBUTE_LIST lst = static_cast<PPROC_THREAD_ATTRIBUTE_LIST>(
    HeapAlloc(GetProcessHeap(), 0, sz) // DeleteProcThreadAttributeList
  );
  if (nullptr == lst) {
    getlasterror(0L);
    return 1;
  }

  if (!InitializeProcThreadAttributeList(lst, 1, 0, &sz)) {
    getlasterror(nts);
    DeleteProcThreadAttributeList(lst);
    return 1;
  }

  if (!UpdateProcThreadAttribute(
    lst, 0, PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, &*ps, sizeof(HANDLE), nullptr, nullptr
  )) {
    getlasterror(0L);
    DeleteProcThreadAttributeList(lst);
    return 1;
  }

  PROCESS_INFORMATION pi = {0};
  STARTUPINFOEX sie = {sizeof(sie)};
  sie.lpAttributeList = lst;
  if (!CreateProcess(
    nullptr, argv[2], nullptr, nullptr, FALSE, EXTENDED_STARTUPINFO_PRESENT, nullptr,
    nullptr, &sie.StartupInfo, &pi
  )) {
    getlasterror(0L);
    DeleteProcThreadAttributeList(lst);
    return 1;
  }

  DeleteProcThreadAttributeList(lst);
  if (nullptr != pi.hThread) {
    if (!CloseHandle(pi.hThread)) getlasterror(0L);
  }
  if (nullptr != pi.hProcess) {
    if (!CloseHandle(pi.hProcess)) getlasterror(0L);
  }

  return 0;
}
