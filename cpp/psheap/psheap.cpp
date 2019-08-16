#include "psheap.hpp"

#include <cstdio>
#include <string>
#include <vector>
#include <locale>

BOOLEAN LocateSigntures(void) {
  RtlCreateQueryDebugBuffer = AddrToFunc(pRtlCreateQueryDebugBuffer);
  if (nullptr == RtlCreateQueryDebugBuffer) return FALSE;

  RtlDestroyQueryDebugBuffer = AddrToFunc(pRtlDestroyQueryDebugBuffer);
  if (nullptr == RtlDestroyQueryDebugBuffer) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  RtlQueryProcessDebugInformation = AddrToFunc(pRtlQueryProcessDebugInformation);
  if (nullptr == RtlQueryProcessDebugInformation) return FALSE;

  return TRUE;
}

void PrintErrMessage(NTSTATUS nts) {
  std::vector<wchar_t> msg(0x100);
  DWORD sz = static_cast<ULONG>(msg.size());
  wprintf(L"[!] %s\n", !FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
    FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr,
    0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &msg[0], sz, nullptr
  ) ? L"Unknown error has been occured." : &msg[0]);
}

class CDbgInf {
private:
  PRTL_DEBUG_INFORMATION m_res;
  NTSTATUS nts;
public:
  CDbgInf(PRTL_DEBUG_INFORMATION res = nullptr) : m_res(res) {}

  CDbgInf(const CDbgInf &) = delete;
  CDbgInf & operator = (const CDbgInf &) = delete;

  ~CDbgInf() {
    if (IsValid()) {
      nts = RtlDestroyQueryDebugBuffer(m_res);
      if (!NT_SUCCESS(nts)) {
        wprintf(L"[!] Debug buffer release faiure: ");
        PrintErrMessage(nts);
      }
      else
        wprintf(L"[*] Debug buffer is successfully released.\n");
    }
  }

  BOOLEAN IsValid() const { return (nullptr != m_res); }

  operator PRTL_DEBUG_INFORMATION() const { return m_res; }
  // PRTL_DEBUG_INFORMATION * operator & () { return &m_res; }
};

int wmain(int argc, wchar_t *argv[]) {
  using namespace std;

  locale::global(locale(""));
  if (!LocateSigntures()) {
    PrintErrMessage(0L);
    return 1;
  }

  vector<wstring> args(argv, argv + argc);
  if (2 != argc) {
    wprintf(L"Usage: %s <PID>\n", args[0].substr(
      args[0].find_last_of(L"\\") + 1, args[0].length()
    ).c_str());
    return 1;
  }

  ULONG pid = wcstoul(argv[1], 0, 0);
  if (0 == pid || ERANGE == errno) {
    wprintf(L"[!] Invalid PID diapason.\n");
    return 1;
  }

  NTSTATUS nts;
  CDbgInf buf = RtlCreateQueryDebugBuffer(0, TRUE);
  if (nullptr == buf) {
    SetLastError(0x01);
    PrintErrMessage(0L);
    return 1;
  }
  wprintf(L"[*] Debug buffer is successfully created.\n");

  nts = RtlQueryProcessDebugInformation(
    reinterpret_cast<HANDLE>(static_cast<ULONGLONG>(pid)),
    RTL_QUERY_PROCESS_HEAP_SUMMARY | RTL_QUERY_PROCESS_HEAP_ENTRIES, buf
  );
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

  ULONG noh, noe;
  PRTL_HEAP_ENTRY rhe = nullptr;
  PRTL_HEAP_INFORMATION rhi = nullptr;
  PRTL_PROCESS_HEAPS rph = (*buf).Heaps;
  for (noh = rph->NumberOfHeaps, rhi = rph->Heaps; 0 < noh; rhi++, --noh) {
    wprintf(L"[*] Heap (%p [%8I64x | %8I64x] [%8x] %x)\n",
      rhi->BaseAddress, rhi->BytesAllocated, rhi->BytesCommitted,
      rhi->NumberOfEntries, rhi->EntryOverhead
    );

    for (noe = rhi->NumberOfEntries, rhe = rhi->Entries; 0 < noe; rhe++, --noe) {
      if (rhe->Flags & RTL_HEAP_SEGMENT)
        wprintf(L"\t*Segment (%p [%8I64x | %8I64x])\n",
          rhe->u.s2.FirstBlock, rhe->u.s2.CommittedSize, rhe->Size
        );
    }
    wprintf(L"\n");
  }

  return 0;
}
