#ifndef UNICODE
  #define UNICODE
#endif

#pragma once

#include <windows.h>

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;

// PEB (Win10)
#ifdef _WIN64
  #define PebLength        (static_cast<SIZE_T>(0x7C8))
  #define PebNumberOfHeaps (static_cast<WORD>(0x0E8))
  #define PebProcessHeaps  (static_cast<WORD>(0x0F0))
#elif _WIN32
  #define PebLength        (static_cast<SIZE_T>(0x480))
  #define PebNumberOfHeaps (static_cast<WORD>(0x088))
  #define PebProcessHeaps  (static_cast<WORD>(0x090))
#endif

#define ProcessBasicInformation 0
#define NT_SUSCCES(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
/*
#pragma comment (lib, "ntdll.lib")

NTSYSCALLAPI
NTSTATUS
NTAPI NtQueryInformationProcess(
   _In_ HANDLE ProcessHandle,
   _In_ PROCESSINFOCLASS ProcessInfoClass,
   _Out_writes_bytes_(ProcessInformationLength) PVOID ProcessInformation,
   _In_ ULONG ProcessInformationLength,
   _Out_opt_ PULONG ReturnLength
);

NTSYSAPI
ULONG
NTAPI RtlNtStatusToDosError(
   _In_ NTSTATUS Status
);
*/
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))
typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);
pNtQueryInformationProcess NtQueryInformationProcess;
pRtlNtStatusToDosError RtlNtStatusToDosError;

typedef struct _PROCESS_BASIC_INFORMATION {
   NTSTATUS  ExitCode;
   PVOID     PebBaseAddress; // PPEB
   ULONG_PTR AffinityNask;
   KPRIORITY BasePriority;
   HANDLE    UniqueProcessId;
   HANDLE    InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;
