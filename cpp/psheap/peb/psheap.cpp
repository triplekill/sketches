#include "psheap.hpp"

#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <locale>

BOOLEAN LocateSignatures(void) {
  NtQueryInformationProcess = AddrToFunc(pNtQueryInformationProcess);
  if (nullptr == NtQueryInformationProcess) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(int argc, wchar_t *argv[]) {
  using namespace std;

  locale::global(locale(""));
  auto PrintErrMessage = [](NTSTATUS nts) {
    vector<wchar_t> msg(0x100);
    DWORD sz = static_cast<DWORD>(msg.size());
    wcout << L"[!] " << (!FormatMessage(
       FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
       FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr,
       0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
       MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &msg[0], sz, nullptr
    ) ? L"Unknown error has been occured." : &msg[0]) << endl;
  };

  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    exit(1);
  }

  vector<wstring> args(argv, argv + argc);
  if (2 != argc) {
    wcout << L"Usage: " << args[0].substr(
      args[0].find_last_of(L"\\") + 1, args[0].length()
    ) << L" <PID>" << endl;
    return 1;
  }

  DWORD pid = wcstoul(argv[1], 0, 0);
  if (0 == pid || ERANGE == errno) {
    wcout << L"[!] Invalid PID has been specified." << endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
     PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid
  )), [&PrintErrMessage](HANDLE *instance) {
    if (*instance) {
      if (!CloseHandle(*instance)) PrintErrMessage(0L);
      else wcout << L"[*] success" << endl;
    }
  });

  if (!*ps) {
    PrintErrMessage(0L);
    return 1;
  }

  PROCESS_BASIC_INFORMATION pbi = {0}; // getting PEB address
  NTSTATUS nts = NtQueryInformationProcess(
    *ps, ProcessBasicInformation, &pbi, sizeof(pbi), nullptr
  );
  if (!NT_SUSCCES(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

  ULONG count = 0; // getting number of heaps
  if (!ReadProcessMemory(
    *ps, static_cast<PCHAR>(pbi.PebBaseAddress) + PebNumberOfHeaps,
    &count, sizeof(ULONG), nullptr
  )) {
    PrintErrMessage(0L);
    return 1;
  }
  wcout << L"[*] process ("
        << argv[1] << L") => " << count << L" heaps" << endl;

  PVOID address = nullptr; // getting address of heaps
  if (!ReadProcessMemory(
    *ps, static_cast<PCHAR>(pbi.PebBaseAddress) + PebProcessHeaps,
    &address, sizeof(PVOID), nullptr
  )) {
    PrintErrMessage(0L);
    return 1;
  }

  vector<PVOID> heaps(sizeof(PVOID) * count);
  if (!ReadProcessMemory(*ps, address, &heaps[0], heaps.size(), nullptr)) {
    PrintErrMessage(0L);
    return 1;
  }
  for (ULONG i = 0; i < count; i++) {
    wcout << i + 1 << L": " << heaps[i] << endl;
  }

  return 0;
}
