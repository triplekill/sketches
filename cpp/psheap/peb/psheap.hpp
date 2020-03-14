#ifndef UNICODE
  #define UNICODE
#endif

#pragma once

#include <windows.h>

#ifdef _M_X64 // WIN10
  // PEB offsets
  #define PebLength            (static_cast<SIZE_T>(0x7C8)) // sizeof(PEB)
  #define PebNumberOfHeaps     (static_cast<USHORT>(0x0E8)) // ULONG  NumberOfHeaps;
  #define PebProcessHeaps      (static_cast<USHORT>(0x0F0)) // PHEAP  ProcessHeaps;
  // HEAP offsets
  #define HeapLength           (static_cast<SIZE_T>(0x2C0)) // sizeof(HEAP)
  #define HeapFlags            (static_cast<USHORT>(0x070)) // ULONG  Flags;
  #define HeapFrontEndHeapType (static_cast<USHORT>(0x1A2)) // BYTE
  #define HeapCounters         (static_cast<USHORT>(0x238)) // HEAP_COUNTERS
#else
  // PEB offsets
  #define PebLength            (static_cast<SIZE_T>(0x480))
  #define PebNumberOfHeaps     (static_cast<USHORT>(0x088))
  #define PebProcessHeaps      (static_cast<USHORT>(0x090))
  // HEAP offsets
  #define HeapLength           (static_cast<SIZE_T>(0x258))
  #define HeapFlags            (static_cast<USHORT>(0x040))
  #define HeapFrontEndHeapType (static_cast<USHORT>(0x0EA))
  #define HeapCounters         (static_cast<USHORT>(0x1F4))
#endif

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;
#define ProcessBasicInformation 0
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))
typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryInformationProcess NtQueryInformationProcess;
pRtlNtStatusToDosError     RtlNtStatusToDosError;

typedef struct _PROCESS_BASIC_INFORMATION {
   NTSTATUS  ExitCode;
   PVOID     PebBaseAddress;
   ULONG_PTR AffinityMask;
   KPRIORITY BasePriority;
   HANDLE    UniqueProcessId;
   HANDLE    InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;

typedef struct _HEAP_COUNTERS {
   UINT_PTR TotalMemoryReserved;
   UINT_PTR TotalMemoryCommitted;
   UINT_PTR TotalMemoryLargeUCR;
   UINT_PTR TotalSizeInVirtualBlocks;
   ULONG    TotalSegments;
   ULONG    TotalUCRs;
   ULONG    CommittOps;
   ULONG    DeCommitOps;
   ULONG    LockAcquires;
   ULONG    LockCollisions;
   ULONG    CommitRate;
   ULONG    DecommittRate;
   ULONG    CommitFailures;
   ULONG    InBlockCommitFailures;
   ULONG    PollIntervalCounter;
   ULONG    DecommitsSinceLastCheck;
   ULONG    HeapPollInterval;
   ULONG    AllocAndFreeOps;
   ULONG    AllocationIndicesActive;
   ULONG    InBlockDeccommits;
   UINT_PTR InBlockDeccomitSize;
   UINT_PTR HighWatermarkSize;
   UINT_PTR LastPolledSize;
} HEAP_COUNTERS, *PHEAP_COUNTERS;
