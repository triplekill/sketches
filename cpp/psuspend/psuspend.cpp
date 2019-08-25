#include "psuspend.hpp"

#include <iostream>
#include <string>
#include <cctype>
#include <vector>
#include <locale>

BOOLEAN LocateSignatures(void) {
  NtQuerySystemInformation = AddrToFunc(pNtQuerySystemInformation);
  if (nullptr == NtQuerySystemInformation) return FALSE;

  NtResumeProcess = AddrToFunc(pNtResumeProcess);
  if (nullptr == NtResumeProcess) return FALSE;

  NtSuspendProcess = AddrToFunc(pNtSuspendProcess);
  if (nullptr == NtSuspendProcess) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

void PrintErrMessage(NTSTATUS nts) {
  std::vector<wchar_t> msg(0x100);
  DWORD sz = static_cast<DWORD>(msg.size());
  std::wcout << (!FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
    FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr,
    0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &msg[0], sz, nullptr
  ) ? L"Unknown error has been occured." : &msg[0]) << std::endl;
}

class COpenProcess {
private:
  HANDLE m_res;
public:
  COpenProcess(HANDLE res = nullptr) : m_res(res) {}

  COpenProcess(const COpenProcess &) = delete;
  COpenProcess & operator = (const COpenProcess &) = delete;

  ~COpenProcess() {
    if (IsValid()) {
      if (!CloseHandle(m_res)) {
        std::wcout << L"[!] Resource release failure: ";
        PrintErrMessage(0L);
      }
      else
        std::wcout << L"[*] Resource has been successfully released." << std::endl;
    }
  }

  BOOLEAN IsValid() const { return (nullptr != m_res); }

  operator HANDLE() const { return m_res; }
  // HANDLE * operator & () { return &m_res; }
};

void PrintUsage(std::wstring app) {
  std::wcout << L"Usage: " << app.substr(app.find_last_of(L"\\") + 1, app.length()
  ) << L" <PID> [/s|/p]\n   -s  suspend process\n   -r  resume process" << std::endl;
}

NTSTATUS IsSuspended(ULONG pid, std::wstring &pname, BOOLEAN &state) {
  ULONG req = 0;
  NTSTATUS nts = NtQuerySystemInformation(SystemProcessInformation, nullptr, 0, &req);
  if (STATUS_INFO_LENGTH_MISMATCH != nts) return nts; // can not get real buffer size

  std::vector<BYTE> buf(static_cast<SIZE_T>(req));
  nts = NtQuerySystemInformation(SystemProcessInformation, &buf[0], req, nullptr);
  if (!NT_SUCCESS(nts)) return nts;

  PSYSTEM_PROCESS_INFORMATION ps = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(&buf[0]);
  while (ps->NextEntryOffset) {
    if (reinterpret_cast<ULONGLONG>(ps->UniqueProcessId) == pid) {
      pname = ps->ImageName.Buffer;
      state = Waiting == ps->Threads[0].ThreadState && Suspended == ps->Threads[0].WaitReason;
      break;
    }
    ps = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(
                                          reinterpret_cast<LPBYTE>(ps) + ps->NextEntryOffset);
  }

  return 0 != pname.length() ? 0L : STATUS_INVALID_PARAMETER;
}

void ChangeProcessState(ULONG pid, std::wstring pname, BOOLEAN suspend) {
  COpenProcess proc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pid);
  if (!proc.IsValid()) {
    std::wcout << L"[!] Open process failure: ";
    PrintErrMessage(0L);
    return;
  }

  std::wcout << L"[*] OpenProcess is done...\n[?] Trying to " << (
    suspend ? L"suspend" : L"resume"
  ) << L" " << pname << std::endl;
  NTSTATUS nts = suspend ? NtSuspendProcess(proc) : NtResumeProcess(proc);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return;
  }
  std::wcout << L"[*] " << pname << L" is " << (
    suspend ? L"suspended" : L"resumed"
  ) << L"..." << std::endl;
}

int wmain(int argc, wchar_t *argv[]) {
  std::locale::global(std::locale(""));
  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  std::vector<std::wstring> args(argv, argv + argc);
  if (!BETWEEN(2, argc, 3)) {
    PrintUsage(args[0]);
    return 1;
  }

  ULONG pid = wcstoul(argv[1], 0, 0);
  if (0 == pid || ERANGE == errno) {
    std::wcout << L"[!] Invalid PID diapason." << std::endl;
    return 1;
  }

  std::wstring pname = L"";
  BOOLEAN state = FALSE;
  NTSTATUS  nts = IsSuspended(pid, pname, state);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

  if (2 == argc) {
    std::wcout << L"[*] " << pname << L" is " << (
      state ? L"suspended" : L"running"
    ) << L"." << std::endl;
    return 0;
  }

  if (3 == argc) {
    if (L'/' != args[2][0] && L'-' != args[2][0] && !args[2][1]) {
      PrintUsage(args[0]);
      return 1;
    }

    switch (towlower(args[2][1])) {
      case L'r':
        if (!state) {
          std::wcout << L"[*] " << pname << L" is already running." << std::endl;
          return 0;
        }
        ChangeProcessState(pid, pname, 0);
      break;
      case L's':
        if (state) {
          std::wcout << L"[*] " << pname << L" is already suspended." << std::endl;
          return 0;
        }
        ChangeProcessState(pid, pname, 1);
      break;
      default: PrintUsage(args[0]); break;
    }
  }

  return 0;
}
