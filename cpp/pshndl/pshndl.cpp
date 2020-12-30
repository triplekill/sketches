#include "pshndl.hpp"

#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <memory>
#include <locale>

BOOLEAN LocateSignatures(void) {
  NtDuplicateObject = AddrToFunc(pNtDuplicateObject);
  if (nullptr == NtDuplicateObject) return FALSE;

  NtQueryInformationProcess = AddrToFunc(pNtQueryInformationProcess);
  if (nullptr == NtQueryInformationProcess) return FALSE;

  NtQueryObject = AddrToFunc(pNtQueryObject);
  if (nullptr == NtQueryObject) return FALSE;

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

  auto getobjectvalue = [&getlasterror](HANDLE duple, ULONG type) {
    vector<UNICODE_STRING> buf(0x1000);
    NTSTATUS nts = NtQueryObject(duple, type, &buf[0], buf.size(), nullptr);
    if (!NT_SUCCESS(nts))
      getlasterror(nts);
    else if (0 != buf[0].Length)
      wcout << buf[0].Buffer;
    vector<UNICODE_STRING> ().swap(buf);
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  if (2 != argc) {
    wstring app(argv[0]);
    wcout << L"Usage: "
          << app.substr(app.find_last_of(L"\\") + 1, app.length())
          << L" <PID>" << endl;
    return 1;
  }

  ULONG pid = wcstoul(argv[1], 0, 0);
  if (ERANGE == errno) {
    wcout << L"[!] Out of range." << endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
    PROCESS_QUERY_INFORMATION | PROCESS_DUP_HANDLE, FALSE, pid
  )), [&getlasterror](HANDLE *instance) {
    if (*instance) {
      if (!CloseHandle(*instance)) getlasterror(0L);
      else wcout << L"[*] successfully released" << endl;
    }
  });

  if (!*ps) {
    getlasterror(0L);
    return 1;
  }
  wcout << L"[*] getting (" << pid << L") process" << endl;
  vector<PROCESS_HANDLE_SNAPSHOT_INFORMATION> snap(0x1000);
  while (!NT_SUCCESS( // iterate till gettting real size of buffer
    NtQueryInformationProcess(*ps, ProcessHandleInformation, &snap[0], snap.size(), nullptr)
  )) { snap.resize(snap.size() * 2); }

  for (int i = 0; i < snap[0].NumberOfHandles; i++) {
    HANDLE duple = INVALID_HANDLE_VALUE;
    NTSTATUS nts = NtDuplicateObject( // required for handle info querying
      *ps, snap[0].Handles[i].HandleValue, NtCurrentProcess(), &duple, 0, 0, DUPLICATE_SAME_ACCESS
    );
    if (!NT_SUCCESS(nts)) {
      // getlasterror(nts);
      continue;
    }

    wcout << snap[0].Handles[i].HandleValue << setw(21);
    getobjectvalue(duple, ObjectTypeInformation);
    wcout << L" ";
    getobjectvalue(duple, ObjectNameInformation);
    wcout << endl;

    if (!CloseHandle(duple)) {
      getlasterror(0L);
    }
  }

  vector<PROCESS_HANDLE_SNAPSHOT_INFORMATION> ().swap(snap);

  return 0;
}
