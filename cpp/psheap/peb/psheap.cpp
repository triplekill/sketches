#include "psheap.hpp"

#include <iostream>
#include <iomanip>
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
    return 1;
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
      else wcout << L"[*] the process is successfully closed" << endl;
    }
  });

  if (!*ps) {
    PrintErrMessage(0L);
    return 1;
  }
  wcout << L"[*] process (" << pid << L") is successfully opened" << endl;

  PROCESS_BASIC_INFORMATION pbi = {0}; // getting PEB address
  NTSTATUS nts = NtQueryInformationProcess(
    *ps, ProcessBasicInformation, &pbi, sizeof(pbi), nullptr
  );
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }
  wcout << L"[*] PEB located at " << pbi.PebBaseAddress << endl;

  ULONG count = 0; // getting number of heaps
  if (!ReadProcessMemory(
    *ps, static_cast<PCHAR>(pbi.PebBaseAddress) + PebNumberOfHeaps,
    &count, sizeof(ULONG), nullptr
  )) {
    PrintErrMessage(0L);
    return 1;
  }
  wcout << L"[*] the process has " << count << L" heaps" << endl;

  PVOID address = nullptr; // getting address of heaps
  if (!ReadProcessMemory(
    *ps, static_cast<PCHAR>(pbi.PebBaseAddress) + PebProcessHeaps,
    &address, sizeof(PVOID), nullptr
  )) {
    PrintErrMessage(0L);
    return 1;
  }
  wcout << L"[*] heaps located at " << address << endl;

  vector<PVOID> heaps(sizeof(PVOID) * count);
  if (!ReadProcessMemory(*ps, address, &heaps[0], heaps.size(), nullptr)) {
    PrintErrMessage(0L);
    return 1;
  }
  wcout << L"No  Heap             Flags    Rsrv(Kb) Commit(Kb) Segments FastHeap" << endl;
  wcout << L"--- -----            ------   -------- ---------- -------- --------" << endl;
  for (ULONG i = 0; i < count; i++) {
    ULONG flags = 0; // getting heap flags
    if (!ReadProcessMemory(
      *ps, static_cast<PCHAR>(heaps[i]) + HeapFlags,
      &flags, sizeof(ULONG), nullptr
    )) continue;

    HEAP_COUNTERS hc = {0};
    if (!ReadProcessMemory(
      *ps, static_cast<PCHAR>(heaps[i]) + HeapCounters,
      &hc, sizeof(HEAP_COUNTERS), nullptr
    )) continue;

    BYTE type = 0; // getting heap type
    if (!ReadProcessMemory(
      *ps, static_cast<PCHAR>(heaps[i]) + HeapFrontEndHeapType,
      &type, sizeof(BYTE), nullptr
    )) continue;

    wcout << setw(2) << setfill(L' ') << i + 1 << L": " // heap number
          << heaps[i] // heap address
          << L" " << hex << setw(8) << setfill(L'0') << flags // flags
          << dec // all other values are decimal
          << L" " << setw(8) << setfill(L' ')
          << hc.TotalMemoryReserved / 1024 // reserved
          << L" " << setw(10) << setfill(L' ')
          << hc.TotalMemoryCommitted / 1024 // commit
          << L" " << setw(8) << setfill(L' ')
          << hc.TotalSegments // segments
          << L" " << setw(8) << setfill(L' ')
          << (2 == type ? L"LFH" : L"") // heap type
          << endl; // end of line
  }

  return 0;
}
