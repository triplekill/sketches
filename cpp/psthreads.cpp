#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <locale>

#pragma comment (lib, "ntdll.lib")

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;

#define SystemExtendedProcessInformation 57
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004L))
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef struct _CLIENT_ID {
   HANDLE UniqueProcess;
   HANDLE UniqueThread;
} CLIENT_ID, *PCLIENT_ID;

typedef enum _KTHREAD_STATE {
   Initialized, Ready, Running, Standby, Terminated, Waiting, Transition, DeferredReady,
   GateWaitObsolete, WaitingForProcessInSwap
} KTHREAD_STATE, *PKTHREAD_STATE;

typedef enum _KWAIT_REASON {
   Executive, FreePage, PageIn, PoolAllocation, DelayExecution, Suspended, UserRequest, WrExecutive,
   WrFreePage, WrPageIn, WrPoolAllocation, WrDelayExecution, WrSuspended, WrUserRequest, WrSpare0,
   WrQueue, WrLpcReceive, WrLpcReply, WrVirtualMemory, WrPageOut, WrRendezvous, WrKeyedEvent,
   WrTerminated, WrProcessInSwap, WrCpuRateControl, WrCalloutStack, WrKernel, WrResource, WrPushLock,
   WrMutex, WrQuantumEnd, WrDispatchInt, WrPreempted, WrYieldExecution, WrFastMutex, WrGuardedMutex,
   WrRundown, WrAlertByThreadId, WrDeferredPreempt, WrPhysicalFault, MaximumWaitReason
} KWAIT_REASON, *PKWAIT_REASON;

typedef struct _SYSTEM_THREAD_INFORMATION {
   LARGE_INTEGER KernelTime;
   LARGE_INTEGER UserTime;
   LARGE_INTEGER CreateTime;
   ULONG         WaitTime;
   PVOID         StartAddress;
   CLIENT_ID     ClieantId;
   KPRIORITY     Priority;
   LONG          BasePriority;
   ULONG         ContextSwitches;
   KTHREAD_STATE ThreadState;
   KWAIT_REASON  WaitReason;
} SYSTEM_THREAD_INFORMATION, *PSYSTEM_THREAD_INFORMATION;

typedef struct _SYSTEM_EXTENDED_THREAD_INFORMATION {
   SYSTEM_THREAD_INFORMATION ThreadInfo;
   PVOID StackBase;
   PVOID StackLimit;
   PVOID Win32StartAddress;
   PVOID TebBase; // PTEB
   ULONG_PTR Reserved2;
   ULONG_PTR Reserved3;
   ULONG_PTR Reserved4;
} SYSTEM_EXTENDED_THREAD_INFORMATION, *PSYSTEM_EXTENDED_THREAD_INFORMATION;

typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct _SYSTEM_PROCESS_INFORMATION {
   ULONG          NextEntryOffset;
   ULONG          NumberOfThreads;
   LARGE_INTEGER  WorkingSetPrivateSize;
   ULONG          HardFaultCount;
   ULONG          NumberOfThreadsHighWatermark;
   ULONGLONG      CycleTime;
   LARGE_INTEGER  CreateTime;
   LARGE_INTEGER  UserTime;
   LARGE_INTEGER  KernelTime;
   UNICODE_STRING ImageName;
   KPRIORITY      BasePriority;
   HANDLE         UniqueProcessId;
   HANDLE         InheritedFromUniqueProcessId;
   ULONG          HandleCount;
   ULONG          SessionId;
   UINT_PTR       UniqueProcessKey;
   SIZE_T         PeakVirtualSize;
   SIZE_T         VirtualSize;
   ULONG          PageFaultCount;
   SIZE_T         PeakWorkingSetSize;
   SIZE_T         WorkingSetSize;
   SIZE_T         QuotaPeakPagedPoolUsage;
   SIZE_T         QuotaPagedPoolUsage;
   SIZE_T         QuotaPeakNonPagedPoolUsage;
   SIZE_T         QuotaNonPagedPoolUsage;
   SIZE_T         PagefileUsage;
   SIZE_T         PeakPagefileUsage;
   SIZE_T         PrivatePageCount;
   LARGE_INTEGER  ReadOperationCount;
   LARGE_INTEGER  WriteOperationCount;
   LARGE_INTEGER  OtherOperationCount;
   LARGE_INTEGER  ReadTransferCount;
   LARGE_INTEGER  WriteTransferCount;
   LARGE_INTEGER  OtherTransferCount;
   SYSTEM_EXTENDED_THREAD_INFORMATION Threads[1];
} SYSTEM_PROCESS_INFORMATION, *PSYSTEM_PROCESS_INFORMATION;

typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQuerySystemInformation NtQuerySystemInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  NtQuerySystemInformation = AddrToFunc(pNtQuerySystemInformation);
  if (nullptr == NtQuerySystemInformation) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(int argc, WCHAR **argv) {
  using namespace std;

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
      wcout << L"[!] LocalFree (" << ::GetLastError() << L") fatal error." << endl;
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  locale::global(locale(""));
  if (2 != argc) {
    wstring app(argv[0]);
    wcout << L"Usage: "
          << app.substr(app.find_last_of(L'\\') + 1, app.length())
          << L" <PID>" << endl;
    return 1;
  }

  ULONG pid{}, req{};
  pid = wcstoul(argv[1], 0, 0);
  if (!pid) {
    wcout << L"[!] Invalid PID value." << endl;
    return 1;
  }

  NTSTATUS nts = ::NtQuerySystemInformation(SystemExtendedProcessInformation, nullptr, 0, &req);
  if (STATUS_INFO_LENGTH_MISMATCH != nts) {
    getlasterror(nts);
    return 1;
  }

  vector<BYTE> buf(req);
  nts = NtQuerySystemInformation(SystemExtendedProcessInformation, &buf[0], req, nullptr);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  PSYSTEM_PROCESS_INFORMATION ps = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(&buf[0]);
  while (ps->NextEntryOffset) {
    if (reinterpret_cast<ULONGLONG>(ps->UniqueProcessId) == pid) {
      wcout << L"[*] " << ps->ImageName.Buffer << L"..." << endl;
      for (ULONG i = 0; i < ps->NumberOfThreads; i++) {
        wcout << L"   ~[" << i + 1 << L"] " << setw(4)
              << reinterpret_cast<ULONGLONG>(ps->Threads[i].ThreadInfo.ClieantId.UniqueThread)
              << L" Win32StartAddress:0x" << ps->Threads[i].Win32StartAddress
              << L"\n\tStack base:0x" << ps->Threads[i].StackBase
              << L" limit:0x" << ps->Threads[i].StackLimit << endl;
      }
      break;
    }
    ps = reinterpret_cast<PSYSTEM_PROCESS_INFORMATION>(reinterpret_cast<PBYTE>(ps) + ps->NextEntryOffset);
  }

  return 0;
}
