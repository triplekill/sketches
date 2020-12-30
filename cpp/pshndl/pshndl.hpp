#ifndef UNICODE
  #define UNICODE
#endif

#pragma once

#include <windows.h>

typedef LONG NTSTATUS;

#define ObjectNameInformation 1
#define ObjectTypeInformation 2
#define ProcessHandleInformation 51
#define NtCurrentProcess() (reinterpret_cast<HANDLE>(static_cast<LONG_PTR>(-1)))
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef NTSTATUS (__stdcall *pNtDuplicateObject)(HANDLE, HANDLE, HANDLE, PHANDLE, ACCESS_MASK, ULONG, ULONG);
typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef NTSTATUS (__stdcall *pNtQueryObject)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtDuplicateObject NtDuplicateObject;
pNtQueryInformationProcess NtQueryInformationProcess;
pNtQueryObject NtQueryObject;
pRtlNtStatusToDosError RtlNtStatusToDosError;

typedef struct _PROCESS_HANDLE_TABLE_ENTRY_INFO {
   HANDLE HandleValue;
   ULONG_PTR HandleCount;
   ULONG_PTR PointerCount;
   ULONG GrantedAccess;
   ULONG ObjectTypeIndex;
   ULONG HandleAttributes;
   ULONG Reserved;
} PROCESS_HANDLE_TABLE_ENTRY_INFO, *PPROCESS_HANDLE_TABLE_ENTRY_INFO;

typedef struct _PROCESS_HANDLE_SNAPSHOT_INFORMATION {
   ULONG_PTR NumberOfHandles;
   ULONG_PTR Reserved;
   PROCESS_HANDLE_TABLE_ENTRY_INFO Handles[1];
} PROCESS_HANDLE_SNAPSHOT_INFORMATION, *PPROCESS_HANDLE_SNAPSHOT_INFORMATION;

typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;
