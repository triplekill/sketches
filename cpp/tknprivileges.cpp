#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <vector>
#include <locale>

typedef LONG NTSTATUS;

#pragma comment (lib, "advapi32.lib")

#define STATUS_BUFFER_TO_SMALL (static_cast<NTSTATUS>(0xC0000023L))
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define NtCurrentProcessToken() (reinterpret_cast<HANDLE>(static_cast<LONG_PTR>(-4)))
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

/*typedef enum _TOKEN_INFORMATION_CLASS {
   TokenUser = 1,
   TokenGroups,
   TokenPrivileges,
   TokenOwner,
   TokenPrimaryGroup,
   TokenDefaultDacl,
   TokenSource,
   TokenType,
   TokenImpersonationLevel,
   TokenStatistics,
   TokenRestrictedSids,
   TokenSessionId,
   TokenGroupsAndPrivileges,
   TokenSessionReference,
   TokenSandBoxInert,
   TokenAuditPolicy,
   TokenOrigin,
   TokenElevationType,
   TokenLinkedToken,
   TokenElevation,
   TokenHasRestrictions,
   TokenAccessInformation,
   TokenVirtualizationAllowed,
   TokenVirtualizationEnabled,
   TokenIntegrityLevel,
   TokenUIAccess,
   TokenMandatoryPolicy,
   TokenLogonSid,
   TokenIsAppContainer,
   TokenCapabilities,
   TokenAppContainerSid,
   TokenAppContainerNumber,
   TokenUserClaimAttributes,
   TokenDeviceClaimAttributes,
   TokenRestrictedUserClaimAttributes,
   TokenRestrictedDeviceClaimAttributes,
   TokenDeviceGroups,
   TokenRestrictedDeviceGroups,
   TokenSecurityAttributes,
   TokenIsRestricted,
   TokenProcessTrustLevel,
   TokenPrivateNameSpace,
   TokenSingletonAttributes,
   TokenBnoIsolation,
   TokenChildProcessFlags,
   TokenIsLessPrivilegedAppContainer,
   TokenIsSandboxed,
   TokenOriginatingProcessTrustLevel,
   MaxTokenInfoClass,
} TOKEN_INFORMATION_CLASS;*/

typedef NTSTATUS (__stdcall *pNtQueryInformationToken)(HANDLE, TOKEN_INFORMATION_CLASS, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryInformationToken NtQueryInformationToken;
pRtlNtStatusToDosError RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  NtQueryInformationToken = AddrToFunc(pNtQueryInformationToken);
  if (nullptr == NtQueryInformationToken) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(void) {
  using namespace std;

  locale::global(locale(""));
  auto getlasterror = [](NTSTATUS nts) {
    HLOCAL loc{};
    DWORD size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&loc), 0, nullptr
    );

    if (!size)
      wcout << L"[?] Unknown error has been occured." << endl;
    else {
      wstring msg(reinterpret_cast<LPWSTR>(loc));
      wcout << L"[!] " << msg.substr(0, size - sizeof(WCHAR)) << endl;
    }

    if (nullptr != LocalFree(loc))
      wcout << L"LocalFree (" << GetLastError() << L") fatal error." << endl;
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  ULONG buf_len{};
  NTSTATUS nts = NtQueryInformationToken(
    NtCurrentProcessToken(), TokenPrivileges, nullptr, 0, &buf_len
  );
  if (STATUS_BUFFER_TO_SMALL != nts) {
    getlasterror(nts);
    return 1;
  }

  vector<TOKEN_PRIVILEGES> privs(buf_len);
  nts = NtQueryInformationToken(
    NtCurrentProcessToken(), TokenPrivileges, &privs[0], privs.size(), &buf_len
  );
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  for (int i = 0; i < privs[0].PrivilegeCount; i++) {
    buf_len = 0;
    LookupPrivilegeName(nullptr, &privs[0].Privileges[i].Luid, nullptr, &buf_len);
    if (ERROR_INSUFFICIENT_BUFFER != GetLastError()) continue;
    wstring name(buf_len, L' ');
    if (!LookupPrivilegeName(nullptr, &privs[0].Privileges[i].Luid, &name[0], &buf_len)) {
      getlasterror(0L);
      continue;
    }

    buf_len = 0;
    DWORD lang{};
    LookupPrivilegeDisplayName(nullptr, &name[0], nullptr, &buf_len, &lang);
    if (ERROR_INSUFFICIENT_BUFFER != GetLastError()) continue;
    wstring desc(buf_len, L' ');
    if (!LookupPrivilegeDisplayName(nullptr, &name[0], &desc[0], &buf_len, &lang)) {
      getlasterror(0L);
      continue;
    }

    wcout << setw(35) << name << L" "
          << privs[0].Privileges[i].Attributes << L" "
          << desc << endl;
  }

  return 0;
}
