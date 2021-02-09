#ifndef _NTAPI_H_
#define _NTAPI_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;

#define STATUS_INFO_LENGTH_MISMATCH (0xC0000004L)
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)

typedef struct _IO_STATUS_BLOCK {
   union {
      NTSTATUS Status;
      PVOID    Pointer;
   };
   ULONG_PTR Information;
} IO_STATUS_BLOCK, *PIO_STATUS_BLOCK;

typedef VOID (*PIO_APC_ROUTINE)(
   PVOID ApcContext,
   PIO_STATUS_BLOCK IoStatusBlock,
   ULONG Reserved
);

typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef enum _FILE_INFORMATION_CLASS { // reduced, key values only
   FileDirectoryInformation = 1,
   FileProcessIdsUsingFileInformation = 47
} FILE_INFORMATION_CLASS, *PFILE_INFORMATION_CLASS;

typedef enum _SYSTEM_INFORMATION_CLASS {
   SystemProcessInformation = 5,
   SystemProcessIdInformation = 88 // since Vista
} SYSTEM_INFORMATION_CLASS;

typedef struct _FILE_DIRECTORY_INFORMATION {
   ULONG NextEntryOffset;
   ULONG FileIndex;
   LARGE_INTEGER CreationTime;
   LARGE_INTEGER LastAccessTime;
   LARGE_INTEGER LastWriteTime;
   LARGE_INTEGER ChangeTime;
   LARGE_INTEGER EndOfFile;
   LARGE_INTEGER AllocationSize;
   ULONG FileAttributes;
   ULONG FileNameLength;
   WCHAR FileName[1];
} FILE_DIRECTORY_INFORMATION, *PFILE_DIRECTORY_INFORMATION;

typedef struct _FILE_PROCESS_IDS_USING_FILE_INFORMATION {
   ULONG NumberOfProcessIdsInList;
   ULONG_PTR ProcessIdList[1];
} FILE_PROCESS_IDS_USING_FILE_INFORMATION, *PFILE_PROCESS_IDS_USING_FILE_INFORMATION;

typedef struct _SYSTEM_PROCESS_INFORMATION {
   ULONG NextEntryOffset;
   ULONG NumberOfThreads;
   LARGE_INTEGER WorkingSetPrivateSize;
   ULONG HardFaultCount;
   ULONG NumBerOfThreadsHighWatermark;
   ULONGLONG CycleTime;
   LARGE_INTEGER CreateTime;
   LARGE_INTEGER UserTime;
   LARGE_INTEGER KernelTime;
   UNICODE_STRING ImageName;
   KPRIORITY BasePriority;
   HANDLE UniqueProcessId;
   HANDLE InheritedFromUniqueProcessId;
   ULONG HandleCount;
   ULONG SessionId;
   ULONG_PTR UniqueProcessKey;
   SIZE_T PeakVirtualSize;
   SIZE_T VirtualSize;
   ULONG PageFaultCount;
   SIZE_T PeakWorkingSetSize;
   SIZE_T WorkingSetSize;
   SIZE_T QuotaPeakPagedPoolUsage;
   SIZE_T QuotaPagedPoolUsage;
   SIZE_T QuotaPeakNonPagedPoolUsage;
   SIZE_T QuotaNonPagedPoolUsage;
   SIZE_T PagefileUsage;
   SIZE_T PeakPagefileUsage;
   SIZE_T PrivatePageCount;
   LARGE_INTEGER ReadOperationCount;
   LARGE_INTEGER WriteOperationCount;
   LARGE_INTEGER OtherOperationCount;
   LARGE_INTEGER ReadTransferCount;
   LARGE_INTEGER WriteTransferCount;
   LARGE_INTEGER OtherTransferCount;
} SYSTEM_PROCESS_INFORMATION, *PSYSTEM_PROCESS_INFORMATION;

typedef struct _SYSTEM_PROCESS_ID_INFORMATION {
   HANDLE ProcessId;
   UNICODE_STRING ImageName;
} SYSTEM_PROCESS_ID_INFORMATION, *PSYSTEM_PROCESS_ID_INFORMATION;

NTSYSCALLAPI
NTSTATUS
NTAPI
NtQueryDirectoryFile(
   _In_ HANDLE FileHandle,
   _In_opt_ HANDLE Event,
   _In_opt_ PIO_APC_ROUTINE ApcRoutine,
   _In_opt_ PVOID ApcContext,
   _Out_ PIO_STATUS_BLOCK IoStatusBlock,
   _Out_writes_bytes_(FileInformationLength) PVOID FileInformation,
   _In_ ULONG FileInformationLength,
   _In_ FILE_INFORMATION_CLASS FileInformationClass,
   _In_ BOOLEAN ReturnSingleEntry,
   _In_opt_ PUNICODE_STRING FileName,
   _In_ BOOLEAN RestartScan
);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtQueryInformationFile(
   _In_ HANDLE FileHandle,
   _Out_ PIO_STATUS_BLOCK IoStatusBlock,
   _Out_writes_bytes_(FileInformationLength) PVOID FileInformation,
   _In_ ULONG FileInformationLength,
   _In_ FILE_INFORMATION_CLASS FileInformationClass
);

NTSYSCALLAPI
NTSTATUS
NTAPI
NtQuerySystemInformation(
   _In_ SYSTEM_INFORMATION_CLASS SystemInformationClass,
   _Out_writes_bytes_opt_(SystemInformationLength) PVOID SystemInformation,
   _In_ ULONG SystemInformationLength,
   _Out_opt_ PULONG ReturnLength
);

NTSYSAPI
ULONG
NTAPI
RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);

#ifdef __cplusplus
}
#endif

#endif
