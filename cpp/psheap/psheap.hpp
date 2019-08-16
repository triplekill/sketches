#ifndef UNICODE
  #define UNICODE
#endif

#pragma once

#include <windows.h>

typedef LONG NTSTATUS;

#define RTL_HEAP_SEGMENT (static_cast<USHORT>(0x0002))
#define RTL_QUERY_PROCESS_HEAP_SUMMARY 0x00000004
#define RTL_QUERY_PROCESS_HEAP_ENTRIES 0x00000010
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef struct _RTL_PROCESS_MODULE_INFORMATION {
   HANDLE Section;
   PVOID  MappedBase;
   PVOID  ImageBase;
   ULONG  ImageSize;
   ULONG  Flags;
   USHORT LoadOrderIndex;
   USHORT InitOrderIndex;
   USHORT LoadCount;
   USHORT OffsetToFileName;
   UCHAR  FullPathName[256]; // 0x100
} RTL_PROCESS_MODULE_INFORMATION, *PRTL_PROCESS_MODULE_INFORMATION;

typedef struct _RTL_PROCESS_MODULES {
   ULONG  NumberOfModules;
   RTL_PROCESS_MODULE_INFORMATION Modules[1];
} RTL_PROCESS_MODULES, *PRTL_PROCESS_MODULES;

typedef struct _RTL_PROCESS_MODULE_INFORMATION_EX {
   ULONG  NextOffset;
   RTL_PROCESS_MODULE_INFORMATION BaseInfo;
   ULONG  ImageChecksum;
   ULONG  TimeDateStamp;
   PVOID  DefaultBase;
} RTL_PROCESS_MODULE_INFORMATION_EX, *PRTL_PROCESS_MODULE_INFORMATION_EX;

typedef struct _RTL_PROCESS_BACKTRACE_INFORMATION {
   PSTR   SymbolicBackTrace;
   ULONG  TraceCount;
   USHORT Index;
   USHORT Depth;
   PVOID  BackTrace[32]; // 0x20
} RTL_PROCESS_BACKTRACE_INFORMATION, *PRTL_PROCESS_BACKTRACE_INFORMATION;

typedef struct _RTL_PROCESS_BACKTRACES {
   ULONG_PTR CommittedMemory;
   ULONG_PTR ReservedMemory;
   ULONG  NumberOfBackTraceLookups;
   ULONG  NumberOfBackTraces;
   RTL_PROCESS_BACKTRACE_INFORMATION BackTraces[1];
} RTL_PROCESS_BACKTRACES, *PRTL_PROCESS_BACKTRACES;

typedef struct _RTL_HEAP_TAG {
   ULONG  NumberOfAllocations;
   ULONG  NumberOfFrees;
   SIZE_T BytesAllocated;
   USHORT TagIndex;
   USHORT CreatorBackTraceIndex;
   WCHAR  TagName[24]; // 0x18
} RTL_HEAP_TAG, *PRTL_HEAP_TAG;

typedef struct _RTL_HEAP_ENTRY {
   SIZE_T Size;
   USHORT Flags;
   USHORT AllocatorBackTraceIndex;
   union {
     struct {
        SIZE_T Settable;
        ULONG  Tag;
     } s1;
     struct {
        SIZE_T CommittedSize;
        PVOID  FirstBlock;
     } s2;
   } u;
} RTL_HEAP_ENTRY, *PRTL_HEAP_ENTRY;

typedef struct _RTL_HEAP_INFORMATION {
   PVOID  BaseAddress;
   ULONG  Flags;
   USHORT EntryOverhead;
   USHORT CreatorBackTraceIndex;
   SIZE_T BytesAllocated;
   SIZE_T BytesCommitted;
   ULONG  NumberOfTags;
   ULONG  NumberOfEntries;
   ULONG  NumberOfPseudoTags;
   ULONG  PseudoTagGranularity;
   ULONG  Reserved[5];
   PRTL_HEAP_TAG Tags;
   PRTL_HEAP_ENTRY Entries;
} RTL_HEAP_INFORMATION, *PRTL_HEAP_INFORMATION;

typedef struct _RTL_PROCESS_HEAPS {
   ULONG NumberOfHeaps;
   RTL_HEAP_INFORMATION Heaps[1];
} RTL_PROCESS_HEAPS, *PRTL_PROCESS_HEAPS;

typedef struct _RTL_PROCESS_LOCK_INFORMATION {
   PVOID  Address;
   USHORT Type;
   USHORT CreatorBackTraceIndex;
   PVOID  OwningThread;
   LONG   LockCount;
   ULONG  ContentionCount;
   ULONG  EntryCount;
   LONG   RecursionCount;
   ULONG  NumberOfWaitingShared;
   ULONG  NumberOfWaitingExclusive;
} RTL_PROCESS_LOCK_INFORMATION, *PRTL_PROCESS_LOCK_INFORMATION;

typedef struct _RTL_PROCESS_LOCKS {
   ULONG  NumberOfLocks;
   RTL_PROCESS_LOCK_INFORMATION Locks[1];
} RTL_PROCESS_LOCKS, *PRTL_PROCESS_LOCKS;

typedef struct _RTL_PROCESS_VERIFIER_OPTIONS {
   ULONG  SizeStruct;
   ULONG  Option;
   UCHAR  OptionData[1];
} RTL_PROCESS_VERIFIER_OPTIONS, *PRTL_PROCESS_VERIFIER_OPTIONS;

typedef struct _RTL_DEBUG_INFORMATION {
   HANDLE SectionHandleClient;
   PVOID  ViewBaseClient;
   PVOID  ViewBaseTarget;
   ULONG_PTR ViewBaseDelta;
   HANDLE EventPairClient;
   HANDLE EventPairTarget;
   HANDLE TargetProcessId;
   HANDLE TargetThreadHandle;
   ULONG  Flags;
   SIZE_T OffsetFree;
   SIZE_T CommitSize;
   SIZE_T ViewSize;
   union {
      PRTL_PROCESS_MODULES Modules;
      PRTL_PROCESS_MODULE_INFORMATION_EX ModuleEx;
   };
   PRTL_PROCESS_BACKTRACES BackTraces;
   PRTL_PROCESS_HEAPS Heaps;
   PRTL_PROCESS_LOCKS Locks;
   PVOID  SpecificHeap;
   HANDLE TargetProcessHandle;
   PRTL_PROCESS_VERIFIER_OPTIONS VerifierOptions;
   PVOID  ProcessHeap;
   HANDLE CriticalSectionHandle;
   HANDLE CriticalSectionOwnerThread;
   PVOID  Reserved[4];
} RTL_DEBUG_INFORMATION, *PRTL_DEBUG_INFORMATION;

/*
NTSYSAPI
PRTL_DEBUG_INFORMATION
NTAPI
RtlCreateQueryDebugBuffer(
   _In_opt_ ULONG MaximumCount,
   _In_ BOOLEAN UseEventPair
);

NTSYSAPI
NTSTATUS
NTAPI
RtlDestroyQueryDebugBuffer(
   _In_ PRTL_DEBUG_INFORMATION Buffer
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);

NTSYSAPI
NTSTATUS
NTAPI
RtlQueryProcessDebugInformation(
   _In_ HANDLE UniqueProcessId,
   _In_ ULONG Flags,
   _In_out_ PRTL_DEBUG_INFORMATION Buffer
);
*/

typedef PRTL_DEBUG_INFORMATION (__stdcall *pRtlCreateQueryDebugBuffer)(ULONG, BOOLEAN);
typedef NTSTATUS (__stdcall *pRtlDestroyQueryDebugBuffer)(PRTL_DEBUG_INFORMATION);
typedef ULONG (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
typedef NTSTATUS (__stdcall *pRtlQueryProcessDebugInformation)(HANDLE, ULONG, PRTL_DEBUG_INFORMATION);

pRtlCreateQueryDebugBuffer RtlCreateQueryDebugBuffer;
pRtlDestroyQueryDebugBuffer RtlDestroyQueryDebugBuffer;
pRtlNtStatusToDosError RtlNtStatusToDosError;
pRtlQueryProcessDebugInformation RtlQueryProcessDebugInformation;
