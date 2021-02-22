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

#pragma comment(lib, "ntdll.lib")

#define SystemSessionProcessInformation (static_cast<SYSTEM_INFORMATION_CLASS>(53))
#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004L))

typedef struct _SYSTEM_SESSION_PROCESS_INFORMATION {
   ULONG SessionId;
   ULONG SizeOfBuf;
   PVOID Buffer;
} SYSTEM_SESSION_PROCESS_INFORMATION, *PSYSTEM_SESSION_PROCESS_INFORMATION;

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
      wcout << L"[!] " << msg.substr(0, size - sizeof(wchar_t)) << endl;
    }

    if (nullptr != LocalFree(loc)) {
#ifdef DEBUG
      wcout << L"LocalFree (" << GetLastError() << L") fatal error." << endl;
#endif
    }
  };

  SYSTEM_SESSION_PROCESS_INFORMATION sspi{};
  vector<BYTE> buf(0x1000);
  sspi.SessionId = 0;
  sspi.SizeOfBuf = buf.size();
  sspi.Buffer    = &buf[0];

  ULONG req = 0;
  NTSTATUS nts = NtQuerySystemInformation(
    SystemSessionProcessInformation, &sspi, sizeof(sspi), &req
  );
  if (STATUS_INFO_LENGTH_MISMATCH != nts) {
    getlasterror(nts);
    return 1;
  }

  buf.resize(req);
  sspi.SizeOfBuf = buf.size();
  sspi.Buffer    = &buf[0];
  nts = NtQuerySystemInformation(
    SystemSessionProcessInformation, &sspi, sizeof(sspi), &req
  );
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    vector<BYTE> ().swap(buf);
    return 1;
  }

  auto adr = &buf[0];
  auto spi = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(adr);
  while (spi->NextEntryOffset) {
    wcout << spi->ImageName.Buffer << L" "
          << reinterpret_cast<ULONG_PTR>(spi->UniqueProcessId)
          << endl;
    adr += spi->NextEntryOffset;
    spi = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(adr);
  }
  vector<BYTE> ().swap(buf);

  return 0;
}
