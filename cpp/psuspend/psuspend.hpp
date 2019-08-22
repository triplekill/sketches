#ifndef UNICODE
  #define UNICODE
#endif

#pragma once

#include <windows.h>

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;

#define SystemProcessInformation 5
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define BETWEEN(Low, Num, High) (((Low) <= (Num)) && ((Num) <= (High)))
#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004L))
#define AddrToFunc(T) (reinterpret_cast<T>( \
                        GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct _CLIENT_ID {
   HANDLE UniqueProcess;
   HANDLE UniqueThread;
} CLIENT_ID, *PCLIENT_ID;

typedef enum _KTHREAD_STATE {
   Initialized,
   Ready,
   Running,
   Standby,
   Terminated,
   Waiting,
   Transition,
   DefferedReady,
   GateWaitObsolete,
   WaitingForProcessInSwap,
   MaximumThreadState
} KTHREAD_STATE, *PKTHREAD_STATE;

typedef enum _KWAIT_REASON {
   Executive,
   FreePage,
   PageIn,
   PoolAllocation,
   DelayExecution,
   Suspended,
   UserRequest,
   WrExecutive,
   WrFreePage,
   WrPageIn,
   WrPoolAllocation,
   WrDelayExecution,
   WrSuspended,
   WrUserRequest,
   WrEventPair,
   WrQueue,
   WrLpcReceive,
   WrLpcReply,
   WrVirtualMemory,
   WrPageOut,
   WrRendezvous,
   WrKeyedEvent,
   WrTerminated,
   WrProcessInSwap,
   WrCpuRateControl,
   WrCalloutStack,
   WrKernel,
   WrResource,
   WrPushLock,
   WrMutex,
   WrQuantumEnd,
   WrDispatchInt,
   WrPreempted,
   WrYieldExecution,
   WrFastMutex,
   WrGuardedMutex,
   WrRundown,
   WrAlertByThreadId,
   WrDeferredPreempt,
   MaximumWaitReason
} KWAIT_REASON, *PKWAIT_REASON;

typedef struct _SYSTEM_THREAD_INFORMATION {
   LARGE_INTEGER KernelTime;
   LARGE_INTEGER UserTime;
   LARGE_INTEGER CreateTime;
   ULONG         WaitTime;
   PVOID         StartAddress;
   CLIENT_ID     ClientId;
   KPRIORITY     Priority;
   LONG          BasePriority;
   ULONG         ContextSwitches;
   KTHREAD_STATE ThreadState;
   KWAIT_REASON  WaitReason;
} SYSTEM_THREAD_INFORMATION, *PSYSTEM_THREAD_INFORMATION;

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
   SYSTEM_THREAD_INFORMATION Threads[1];
} SYSTEM_PROCESS_INFORMATION, *PSYSTEM_PROCESS_INFORMATION;

/*
NTSYSCALLAPI
NTSTATUS
NTAPI
NtQuerySystemInformation(
   _In_ SYSTEM_INFORMATION_CLASS SystemInformationClass,
   _Out_write_bytes_opt_(SystemInformationLength) PVOID SystemInformation,
   _In_ ULONG SystemInformationLength,
   _Out_opt_ PULONG RetutnLength
);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtResumeProcess(
   _In_ HANDLE ProcessHandle
);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtSuspendProcess(
   _In_ HANDLE ProcessHandle
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);
*/

typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef NTSTATUS (__stdcall *pNtResumeProcess)(HANDLE);
typedef NTSTATUS (__stdcall *pNtSuspendProcess)(HANDLE);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQuerySystemInformation NtQuerySystemInformation;
pNtResumeProcess NtResumeProcess;
pNtSuspendProcess NtSuspendProcess;
pRtlNtStatusToDosError RtlNtStatusToDosError;
