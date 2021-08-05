#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h>
#include <stdio.h>
#include <wchar.h>
#include <locale.h>

#pragma comment (lib, "ntdll.lib")

typedef LONG  NTSTATUS;
typedef SHORT   CSHORT;
#define ProcessUptimeInformation ((PROCESS_INFORMATION_CLASS)(0x58))

typedef struct _PROCESS_UPTIME_INFORMATION {
   ULONGLONG QueryInterruptTime;
   ULONGLONG QueryUnbiasedTime;
   ULONGLONG EndInterruptTime;
   ULONGLONG TimeSinceCreation;
   ULONGLONG Uptime;
   ULONGLONG SuspendedTime;
   union {
      ULONG HangCount : 4;
      ULONG GhostCount : 4;
      ULONG Crashed : 1;
      ULONG Terminated : 1;
   };
} PROCESS_UPTIME_INFORMATION, *PPROCESS_UPTIME_INFORMATION;

typedef struct _TIME_FIELDS {
   CSHORT Year;
   CSHORT Month;
   CSHORT Day;
   CSHORT Hour;
   CSHORT Minute;
   CSHORT Second;
   CSHORT Milliseconds;
   CSHORT Weekday;
} TIME_FIELDS, *PTIME_FIELDS;

void getlasterror(NTSTATUS nts) {
  HLOCAL msg = NULL;
  DWORD size = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    NULL, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&msg, 0, NULL
  );

  if (0 >= size)
    wprintf(L"[?] Unknown error has been occured.\n");
  else
    wprintf(L"[!] %.*s\n", (INT)(size - sizeof(WCHAR)), (LPWSTR)msg);

  if (NULL != LocalFree(msg))
    wprintf(L"[!] LocalFree (%d) fatal error.\n", GetLastError());
}

void getelapsedtime(WCHAR *msg, ULONGLONG val) {
  TIME_FIELDS tf = {0};
  RtlTimeToElapsedTimeFields((PLARGE_INTEGER)&val, &tf);
  wprintf(L"%-15s: %hu.%02hu:%02hu:%02hu\n", msg, tf.Day, tf.Hour, tf.Minute, tf.Second);
}

int wmain(int argc, WCHAR **argv) {
  WCHAR   *app;
  HANDLE    ps;
  NTSTATUS nts;
  PROCESS_UPTIME_INFORMATION pui = {0};

  _wsetlocale(LC_CTYPE, L"");
  if (2 != argc) {
    app = wcsrchr(argv[0], L'\\');
    wprintf(L"Usage: %s <PID>\n", app ? ++app : argv[0]);
    return 1;
  }

  ps = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, wcstoul(argv[1], NULL, 0));
  if (NULL == ps) {
    getlasterror(0L);
    return 1;
  }

  nts = NtQueryInformationProcess(ps, ProcessUptimeInformation, &pui, sizeof(pui), NULL);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    if (!CloseHandle(ps)) getlasterror(0L);
    return 1;
  }

  getelapsedtime(L"Since creation", pui.TimeSinceCreation);
  getelapsedtime(L"Total running ", pui.Uptime);

  if (!CloseHandle(ps)) getlasterror(0L);

  return 0;
}
