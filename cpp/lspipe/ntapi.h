#ifndef _NTAPI_H_
#define _NTAPI_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef LONG NTSTATUS;

#define STATUS_INFO_LENGTH_MISMATCH ((NTSTATUS)0xC0000004)
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
   FilePipeLocalInformation = 24,
   FileProcessIdsUsingFileInformation = 47
} FILE_INFORMATION_CLASS, *PFILE_INFORMATION_CLASS;

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

#ifdef UNICODE
  #define CArray(x) L#x,
#else
  #define CArray(x) #x,
#endif

#define PipeConfiguration(T) T(Inbound) T(Outbound) T(Duplex)
#define PipeState(T) T(Unknown) T(Disconnected) T(Listening) T(Connected) T(Closing)

typedef struct _FILE_PIPE_LOCAL_INFORMATION {
   ULONG NamedPipeType;
   ULONG NamedPipeConfiguration;
   ULONG MaximumInstances; // usually the maximum value of unsigned long
   ULONG CurrentInstances;
   ULONG InboundQuota;
   ULONG ReadDataAvailable;
   ULONG OutboundQuota;
   ULONG WriteQuotaAvailable;
   ULONG NamedPipeState;
   ULONG NamePipeEnd;
} FILE_PIPE_LOCAL_INFORMATION, *PFILE_PIPE_LOCAL_INFORMATION;

typedef struct _FILE_PROCESS_IDS_USING_FILE_INFORMATION {
   ULONG NumberOfProcessIdsInList;
   ULONG_PTR ProcessIdList[1];
} FILE_PROCESS_IDS_USING_FILE_INFORMATION, *PFILE_PROCESS_IDS_USING_FILE_INFORMATION;

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
