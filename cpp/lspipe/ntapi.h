#ifndef _NTAPI_H_
#define _NTAPI_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef LONG NTSTATUS;

#define SE_DEBUG_PRIVILEGE (20)
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
   SystemProcessIdInformation = 88
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
   ULONG_PTR ProcessIdsList[1];
} FILE_PROCESS_IDS_USING_FILE_INFORMATION, *PFILE_PROCESS_IDS_USING_FILE_INFORMATION;

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
NTSTATUS
NTAPI
RtlAdjustPrivilege(
   _In_ ULONG Privilege,
   _In_ BOOLEAN Enable,   // TRUE - enable otherwise disable
   _In_ BOOLEAN Clieant,  // TRUE - calling thread otherwise process
   _Out_ PBOOLEAN Enabled // whether privilege was previously enabled
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
