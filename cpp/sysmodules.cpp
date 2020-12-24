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

#define SystemModuleInformation 11
#define STATUS_INFO_LENGTH_MISMATCH (static_cast<NTSTATUS>(0xC0000004L))
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>( \
                       GetProcAddress(GetModuleHandle(L"ntdll.dll") , (&((#T)[1])))))

typedef NTSTATUS (__stdcall *pNtQuerySystemInformation)(ULONG, PVOID, ULONG, PULONG);
typedef NTSTATUS (__stdcall *pRtlQueryModuleInformation)(PULONG, ULONG, PVOID);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQuerySystemInformation NtQuerySystemInformation;
pRtlQueryModuleInformation RtlQueryModuleInformation;
pRtlNtStatusToDosError RtlNtStatusToDosError;

typedef struct _RTL_PROCESS_MODULE_INFORMATION {
   HANDLE Section;
   PVOID  MappedBase;
   PVOID  ImageBase;
   ULONG  ImageSize;
   ULONG  Flags;
   USHORT LoadOrderIndex;
   USHORT InitOrderIndex;
   USHORT LoadCount;
   USHORT OffsetToFileName;
   UCHAR  FullPathName[256];
} RTL_PROCESS_MODULE_INFORMATION, *PRTL_PROCESS_MODULE_INFORMATION;

typedef struct _RTL_PROCESS_MODULES {
   ULONG NumberOfModules;
   RTL_PROCESS_MODULE_INFORMATION Modules[1];
} RTL_PROCESS_MODULES, *PRTL_PROCESS_MODULES;

typedef struct _RTL_MODULE_BASIC_INFO {
   PVOID  ImageBase;
} RTL_MODULE_BASIC_INFO, *PRTL_MODULE_BASIC_INFO;

typedef struct _RTL_MODULE_EXTENDED_INFO {
   RTL_MODULE_BASIC_INFO BasicInfo;
   ULONG  ImageSize;
   USHORT FileNameOffset;
   UCHAR  FullPathName[256];
} RTL_MODULE_EXTENDED_INFO, *PRTL_MODULE_EXTENDED_INFO;

BOOLEAN LocateSignatures(void) {
  NtQuerySystemInformation = AddrToFunc(pNtQuerySystemInformation);
  if (nullptr == NtQuerySystemInformation) return FALSE;

  RtlQueryModuleInformation = AddrToFunc(pRtlQueryModuleInformation);
  if (nullptr == RtlQueryModuleInformation) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

NTSTATUS NtGetSystemModules(void) {
  ULONG buf_len = 0;
  NTSTATUS nts = NtQuerySystemInformation(SystemModuleInformation, nullptr, 0, &buf_len);
  if (STATUS_INFO_LENGTH_MISMATCH != nts) return nts;

  std::vector<RTL_PROCESS_MODULES> modules(buf_len);
  nts = NtQuerySystemInformation(SystemModuleInformation, &modules[0], buf_len, nullptr);
  if (!NT_SUCCESS(nts)) return nts;

  for (ULONG i = 0; i < modules[0].NumberOfModules; i++) {
    std::cout << modules[0].Modules[i].ImageBase << std::setw(10)
      << modules[0].Modules[i].ImageSize << " "
      << modules[0].Modules[i].FullPathName << std::endl;
  }

  return 0L;
}

NTSTATUS RtlGetSystemModules(void) {
  ULONG buf_len = 0, size = sizeof(RTL_MODULE_EXTENDED_INFO);
  NTSTATUS nts = RtlQueryModuleInformation(&buf_len, size, nullptr);
  if (!NT_SUCCESS(nts)) return nts;

  std::vector<RTL_MODULE_EXTENDED_INFO> modules(buf_len / size);
  nts = RtlQueryModuleInformation(&buf_len, size, &modules[0]);
  if (!NT_SUCCESS(nts)) return nts;

  for (auto &module : modules) {
    std::cout << module.BasicInfo.ImageBase << std::setw(10)
     << module.ImageSize << " " << module.FullPathName << std::endl;
  }

  return 0L;
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

  NTSTATUS nts = NtGetSystemModules(); //RtlGetSystemModules();
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  return 0;
}
