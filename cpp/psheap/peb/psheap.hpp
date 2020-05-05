#ifndef UNICODE
  #define UNICODE
#endif

#pragma once

#include <windows.h>

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;

#define ProcessBasicInformation 0
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))
typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryInformationProcess NtQueryInformationProcess;
pRtlNtStatusToDosError RtlNtStatusToDosError;

typedef struct _PROCESS_BASIC_INFORMATION {
   NTSTATUS  ExitCode;
   PVOID     PebBaseAddress; // PPEB
   ULONG_PTR AffinityMask;
   KPRIORITY BasePriority;
   HANDLE    UniqueProcessId;
   HANDLE    InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;

#ifdef _M_X64
  #define PebLength        (static_cast<SIZE_T>(0x7C8)) // sizeof(PEB)
  #define PebNumberOfHeaps (static_cast<USHORT>(0x0E8)) // ULONG NumberOfHeaps;
  #define PebProcessHeaps  (static_cast<USHORT>(0x0F0)) // PHEAP ProcessHeaps;
#else
  #define PebLength        (static_cast<SIZE_T>(0x480))
  #define PebNumberOfHeaps (static_cast<USHORT>(0x088))
  #define PebProcessHeaps  (static_cast<USHORT>(0x090))
#endif

typedef struct _HEAP_UNPACKED_ENTRY {
#ifdef _M_X64
   PVOID PreviousBlockPrivateData;
#endif
   union {
      struct {
         USHORT Size;
         UCHAR  Flags;
         UCHAR  SmallTagIndex;
      };
#ifdef _M_X64
      struct {
         ULONG  SubSegmentCode;
         USHORT PreviousSize;
         union {
            UCHAR SegmentOffset;
            UCHAR LFHFlags;
         };
         UCHAR UnusedBytes;
      };
      ULONGLONG CompactHeader;
#else
      ULONG SubSegmentCode;
#endif
   };
#ifndef _M_X64
   USHORT PreviousSize;
   union {
      UCHAR SegmentOffset;
      UCHAR LFHFlags;
   };
   UCHAR UnusedBytes;
#endif
} HEAP_UNPACKED_ENTRY, *PHEAP_UNPACKED_ENTRY;

typedef struct _HEAP_EXTENDED_ENTRY {
#ifdef _M_X64
   PVOID Reserved;
#endif
   union {
      struct {
         USHORT FunctionIndex;
         USHORT ContextValue;
      };
      ULONG InterceptorValue;
   };
   USHORT UnusedBytesLength;
   UCHAR  EntryOffset;
   UCHAR  ExtendedBlockSignature;
} HEAP_EXTENDED_ENTRY, *PHEAP_EXTENDED_ENTRY;

typedef struct _HEAP_ENTRY {
   union {
      HEAP_UNPACKED_ENTRY UnpackedEntry;
      struct {
#ifdef _M_X64
         PVOID PreviousBlockPrivateData;
         union {
            struct {
               USHORT Size;
               UCHAR  Flags;
               UCHAR  SmallTagIndex;
            };
            struct {
               ULONG  SubSegmentCode;
               USHORT PreviousSize;
               union {
                  UCHAR SegmentOffset;
                  UCHAR LFHFlags;
               };
               UCHAR UnusedBytes;
            };
            ULONGLONG CompactHeader;
         };
#else
         USHORT Size;
         UCHAR  Flags;
         UCHAR  SmallTagIndex;
#endif
      };
#ifndef _M_X64
      struct {
         ULONG  SubSegmentCode;
         USHORT PreviousSize;
         union {
            UCHAR SegmentOffset;
            UCHAR LFHFlags;
         };
         UCHAR UnusedBytes;
      };
#endif
      HEAP_EXTENDED_ENTRY ExtendedEntry;
      struct {
#ifdef _M_X64
         PVOID Reserved;
         union {
            struct {
               USHORT FunctionIndex;
               USHORT ContextValue;
            };
            ULONG InterceptorValuer;
         };
         USHORT UnusedBytesLength;
         UCHAR  EntryOffset;
         UCHAR  ExtendedBlockSignature;
#else
         USHORT FunctionIndex;
         USHORT ContextValue;
#endif
      };
      struct {
#ifdef _M_X64
         PVOID ReservedForAlignment;
         union {
            struct {
               ULONG Code1;
               union {
                  struct {
                     USHORT Code2;
                     UCHAR  Code3;
                     UCHAR  Code4;
                  };
                  ULONG Code234;
               };
            };
            ULONGLONG AgregateCode;
         };
#else
         ULONG  InterceptorValue;
         USHORT UnusedBytesLength;
         UCHAR  EntryOffset;
         UCHAR  ExtendedBlockSignature;
#endif
      };
#ifndef _M_X64
      struct {
         ULONG Code1;
         union {
            struct {
               USHORT Code2;
               UCHAR  Code3;
               UCHAR  Code4;
            };
            ULONG Code234;
         };
      };
      ULONGLONG AgregateCode;
#endif
   };
} HEAP_ENTRY, *PHEAP_ENTRY;

typedef struct _HEAP_SEGMENT {
   HEAP_ENTRY Entry;
   ULONG  SegmentSignature;
   ULONG  SegmentFlags;
   LIST_ENTRY SegmentListEntry;
   struct _HEAP *Heap;
   PVOID  BaseAddress;
   ULONG  NumberOfPages;
   PHEAP_ENTRY FirstEntry;
   PHEAP_ENTRY LastValidEntry;
   ULONG  NumberOfUnCommittedPages;
   ULONG  NumberOfUnCommittedRanges;
   USHORT SegmentAllocatorBackTraceIndex;
   USHORT Reserved;
   LIST_ENTRY UCRSegmentList;
} HEAP_SEGMENT, *PHEAP_SEGMENT;

typedef struct _HEAP_TAG_ENTRY {
   ULONG  Allocs;
   ULONG  Frees;
   SIZE_T Size;
   USHORT TagIndex;
   USHORT CreatorBackTraceIndex;
   WCHAR  TagName[24];
} HEAP_TAG_ENTRY, *PHEAP_TAG_ENTRY;

typedef struct _HEAP_PSEUDO_TAG_ENTRY {
   ULONG  Allocs;
   ULONG  Frees;
   SIZE_T Size;
} HEAP_PSEUDO_TAG_ENTRY, *PHEAP_PSEUDO_TAG_ENTRY;

/*
typedef struct _RTL_CRITICAL_SECTION_DEBUG {
   USHORT Type;
   USHORT CreatorBackTraceIndex;
   struct RTL_CRITICAL_SECTION *CriticalSection;
   LIST_ENTRY ProcessLocksList;
   ULONG  EntryCount;
   ULONG  ContentionCount;
   ULONG  Flags;
   USHORT CreatorBackTraceIndexHigh;
   USHORT SpareUSHORT;
} RTL_CRITICAL_SECTION_DEBUG, *PRTL_CRITICAL_SECTION_DEBUG;

typedef struct _RTL_CRITICAL_SECTION {
   PRTL_CRITICAL_SECTION_DEBUG DebugInfo;
   LONG   LockCount;
   LONG   RecursionCount;
   HANDLE OwningThread;
   HANDLE LockSemaphore;
   SIZE_T SpinCount;
} RTL_CRITICAL_SECTION, *PRTL_CRITICAL_SECTION;
*/
typedef struct _HEAP_LOCK {
   union {
      RTL_CRITICAL_SECTION CriticalSection;
   } Lock;
} HEAP_LOCK, *PHEAP_LOCK;

typedef
_Function_class_(RTL_HEAP_COMMIT_ROUTINE)
_IRQL_requires_same_
NTSTATUS
NTAPI
RTL_HEAP_COMMIT_ROUTINE (
   _In_    PVOID   Base,
   _Inout_ PVOID   *CommitAddress,
   _Inout_ PSIZE_T CommitSize
);
typedef RTL_HEAP_COMMIT_ROUTINE *PRTL_HEAP_COMMIT_ROUTINE;
/*
typedef union _RTL_RUN_ONCE {
   PVOID     Ptr;
   ULONG_PTR Value;
   ULONG_PTR State : 2;
} RTL_RUN_ONCE, *PRTL_RUN_ONCE;
*/
typedef struct _RTL_HEAP_MEMORY_LIMIT_DATA {
   SIZE_T CommitLimitBytes;
   SIZE_T CommitLimitFailureCode;
   SIZE_T MaxAllocationSizeBytes;
   SIZE_T AllocationLimitFailureCode;
} RTL_HEAP_MEMORY_LIMIT_DATA, *PRTL_HEAP_MEMORY_LIMIT_DATA;

typedef struct _HEAP_COUNTERS {
   SIZE_T TotalMemoryReserved;
   SIZE_T TotalMemoryCommitted;
   SIZE_T TotalMemoryLargeUCR;
   SIZE_T TotalSizeInVirtualBlocks;
   ULONG  TotalSegments;
   ULONG  TotalUCRs;
   ULONG  CommittOps;
   ULONG  DeCommitOps;
   ULONG  LockAcquires;
   ULONG  LockCollisions;
   ULONG  CommitRate;
   ULONG  DecommittRate;
   ULONG  CommitFailures;
   ULONG  InBlockCommitFailures;
   ULONG  PollIntervalCounter;
   ULONG  DecommitsSinceLastCheck;
   ULONG  HeapPollInterval;
   ULONG  AllocAndFreeOps;
   ULONG  AllocationIndicesActive;
   ULONG  InBlockDeccommits;
   SIZE_T InBlockDeccomitSize;
   SIZE_T HighWatermarkSize;
   SIZE_T LastPolledSize;
} HEAP_COUNTERS, *PHEAP_COUNTERS;

typedef struct _HEAP_TUNING_PARAMETERS {
   ULONG  CommittThresholdShift;
   SIZE_T MaxPreCommittedThreshold;
} HEAP_TUNING_PARAMETERS, *PHEAP_TUNING_PARAMETERS;

typedef struct _HEAP {
   union {
      HEAP_SEGMENT Segment;
      struct {
         HEAP_ENTRY Entry;
         ULONG SegmentSignature;
         ULONG SegmentFlags;
         LIST_ENTRY SegmentListEntry;
         struct _HEAP *Heap;
         PVOID  BaseAddress;
         ULONG  NumberOfPages;
         PHEAP_ENTRY FirstEntry;
         PHEAP_ENTRY LastValidEntry;
         ULONG  NumberOfUnCommittedPages;
         ULONG  NumberOfUnCommittedRanges;
         USHORT SegmentAllocatorBackTraceIndex;
         USHORT Reserved;
         LIST_ENTRY UCRSegmentList;
         ULONG  Flags;
         ULONG  ForceFlags;
         ULONG  CompatibilityFlags;
         ULONG  EncodeFlagMask;
         HEAP_ENTRY Encoding;
         ULONG  Interceptor;
         ULONG  VirtualMemoryThreshold;
         ULONG  Signature;
         SIZE_T SegmentReserve;
         SIZE_T SegmentCommit;
         SIZE_T DeCommitFreeBlockThreshold;
         SIZE_T DeCommitTotalFreeThreshold;
         SIZE_T TotalFreeSize;
         SIZE_T MaximumAllocationSize;
         USHORT ProcessHeapsListIndex;
         USHORT HeaderValidateLength;
         PVOID  HeaderValidateCopy;
         USHORT NextAvailableTagIndex;
         USHORT MaximumTagIndex;
         PHEAP_TAG_ENTRY TagEntries;
         LIST_ENTRY UCRList;
         ULONG_PTR AlignRound;
         ULONG_PTR AlignMask;
         LIST_ENTRY VirtualAllocBlocks;
         LIST_ENTRY SegmentList;
         USHORT AllocatorBackTraceIndex;
         ULONG  NonDedicatedListLength;
         PVOID  BlockIndex;
         PVOID  UCRIndex;
         PHEAP_PSEUDO_TAG_ENTRY PseudoTagEntries;
         LIST_ENTRY FreeLists;
         PHEAP_LOCK LockVariable;
         PRTL_HEAP_COMMIT_ROUTINE CommitRoutine;
         RTL_RUN_ONCE StackTraceInitVar;
         RTL_HEAP_MEMORY_LIMIT_DATA CommitLimitData;
         PVOID  FrontEndHeap;
         USHORT FrontHeapLockCount;
         UCHAR  FrontEndHeapType;
         UCHAR  RequestedFrontEndHeapType;
         PWSTR  FrontEndHeapUsageData;
         USHORT FrontEndHeapMaximumIndex;
         UCHAR  FrontEndHeapStatusBitmap[129];
         HEAP_COUNTERS Counters;
         HEAP_TUNING_PARAMETERS TuningParameters;
      } DUMMYSTRUCTNAME;
   } DUMMYUNIONNAME;
} HEAP, *PHEAP;
