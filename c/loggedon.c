#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <ntsecapi.h>
#include <stdio.h>
#include <locale.h>

#pragma comment (lib, "advapi32.lib")
#pragma comment (lib, "secur32.lib")

typedef LONG NTSTATUS;

#define NtCurrentProcessToken() ((HANDLE)(LONG_PTR)-4)
#define NT_SUCCESS(Status) (((NTSTATUS)(Status)) >= 0L)

void GetLastErrorMsg(NTSTATUS nts) {
  HLOCAL msg = NULL;
  DWORD size = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    NULL, 0L != nts ? LsaNtStatusToWinError(nts) : GetLastError(),
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPWSTR)&msg, 0, NULL
  );

  if (0 == size)
    printf("[?] Unknown error has been occured.\n");
  else
    printf("[!] %.*ws\n", (INT)(size - sizeof(WCHAR)), (LPWSTR)msg);

  if (NULL != LocalFree(msg))
    printf("LocalFree (%d) fatal error.\n", GetLastError());
}

int main(void) {
  BOOL status;
  NTSTATUS ntstatus;
  TOKEN_STATISTICS ts = {0};
  DWORD tslen = sizeof(TOKEN_STATISTICS);
  PSECURITY_LOGON_SESSION_DATA pslsd = NULL;
  FILETIME ft = {0};
  SYSTEMTIME st = {0};

  _wsetlocale(LC_CTYPE, L"");
  status = GetTokenInformation(
    NtCurrentProcessToken(), TokenStatistics, &ts, tslen, &tslen
  );
  if (!status) {
    GetLastErrorMsg(0L);
    return 1;
  }

  ntstatus = LsaGetLogonSessionData(&ts.AuthenticationId, &pslsd);
  if (!NT_SUCCESS(ntstatus)) {
    GetLastErrorMsg(ntstatus);
    return 1;
  }

  ft = *(FILETIME *)&pslsd->LogonTime;
  printf("%wZ: ", pslsd->UserName);
  if (!FileTimeToLocalFileTime(&ft, &ft)) {
    GetLastErrorMsg(0L);
    printf("\n");
    return 1;
  }
  if (!FileTimeToSystemTime(&ft, &st)) {
    GetLastErrorMsg(0L);
    printf("\n");
    return 1;
  }
  printf("logged at %02hu/%02hu/%02hu %02hu:%02hu:%02hu\n",
    st.wMonth, st.wDay, st.wYear,
    st.wHour, st.wMinute, st.wSecond
  );

  ntstatus = LsaFreeReturnBuffer(pslsd);
  if (!NT_SUCCESS(ntstatus)) {
    GetLastErrorMsg(ntstatus);
    return 1;
  }

  return 0;
}
