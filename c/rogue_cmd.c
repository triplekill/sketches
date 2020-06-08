#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h> // already contains NtQueryInformationProcess and RtlNtStatusToDosError
#include <intrin.h>
#include <stdio.h>
#include <locale.h>

typedef LONG NTSTATUS;

#define ProcessCommandLineInformation 60
#define STATUS_INFO_LENGTH_MISMATCH (0xC0000004L)
#define AddrToFunc(T) ((T)GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))))
#define sym(x) ((int)((x) - sizeof(WCHAR)))
#define OverrideUnicodeString(s, v) {             \
  ((s).Length) = ((sizeof(v)) - (sizeof(WCHAR))); \
  ((s).MaximumLength) = (sizeof(v));              \
  ((s).Buffer) = v;                               \
};

typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryInformationProcess m_NtQueryInformationProcess;
pRtlNtStatusToDosError m_RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  m_NtQueryInformationProcess = AddrToFunc(pNtQueryInformationProcess);
  if (NULL == m_NtQueryInformationProcess) return FALSE;

  m_RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (NULL == m_RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

void PrintErrMessage(NTSTATUS nts) {
  HLOCAL msg = NULL;
  DWORD  len = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    NULL, 0L != nts ? m_RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&msg, 0, NULL
  );
  if (0 != len)
    wprintf(L"%.*s\n", sym(len), (LPWSTR)msg);
  else
    wprintf(L"Unknown error has been occured.\n");

  if (NULL != LocalFree(msg))
    wprintf(L"LocalFree: fatal error.");
}

NTSTATUS GetCurrentProcessCmd(void) {
  ULONG req = 0;
  NTSTATUS nts = 0L;
  PUNICODE_STRING cmd;

  nts = m_NtQueryInformationProcess(
    GetCurrentProcess(), ProcessCommandLineInformation, NULL, 0, &req
  );
  if (!NT_SUCCESS(nts) && STATUS_INFO_LENGTH_MISMATCH != nts)
    return nts;

  cmd = (PUNICODE_STRING)malloc(req);
  if (NULL != cmd) {
    nts = m_NtQueryInformationProcess(
      GetCurrentProcess(), ProcessCommandLineInformation, cmd, req, NULL
    );

    if (NT_SUCCESS(nts))
      wprintf(L"%s\n", cmd->Buffer);

    free(cmd);
    return nts;
  }
  else
    return STATUS_NO_MEMORY;
}

int wmain(void) {
  NTSTATUS nts;
  PPEB peb = NULL;
  WCHAR str[] = L"C:\\Windows\\System32\\notepad.exe";

  _wsetlocale(LC_CTYPE, L"");
  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  nts = GetCurrentProcessCmd();
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

#ifdef _M_X64
  peb = (PPEB)__readgsqword(0x60);
#else
  peb = (PPEB)__readfsdword(0x30);
#endif
  OverrideUnicodeString(peb->ProcessParameters->CommandLine, str);
  nts = GetCurrentProcessCmd();
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }

  return 0;
}
