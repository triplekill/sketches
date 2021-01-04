/*
 * getting PEB address (against ASLR and NtQueryInformationProcess)
 */
#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <tlhelp32.h>
#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <locale>

typedef LONG NTSTATUS;

#ifdef _M_X64
  #define PebImgBase 0x10
#else
  #define PebImgBase 0x08
#endif
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef enum _MEMORY_INFORMATION_CLASS {
   MemoryBasicInformation,
   MemoryWorkingSetInformation,
   MemoryMappedFilenameInformation,
   MemoryRegionInformation,
   MemoryWorkingSetExInformation,
   MemorySharedCommitInformation,
   MemoryImageInformation,
   MemoryRegionInformationEx,
   MemoryPrivilegedBasicInformation,
   MemoryEnclaveImageInformation,
   MemoryBasicInformationCapped
} MEMORY_INFORMATION_CLASS;

typedef NTSTATUS (__stdcall *pNtQueryVirtualMemory)(HANDLE, PVOID, MEMORY_INFORMATION_CLASS, PVOID, SIZE_T, PSIZE_T);
typedef NTSTATUS (__stdcall *pNtReadVirtualMemory)(HANDLE, PVOID, PVOID, SIZE_T, PSIZE_T);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryVirtualMemory NtQueryVirtualMemory;
pNtReadVirtualMemory NtReadVirtualMemory;
pRtlNtStatusToDosError RtlNtStatusToDosError;

BOOLEAN LocateSignatures(void) {
  NtQueryVirtualMemory = AddrToFunc(pNtQueryVirtualMemory);
  if (nullptr == NtQueryVirtualMemory) return FALSE;

  NtReadVirtualMemory = AddrToFunc(pNtReadVirtualMemory);
  if (nullptr == NtReadVirtualMemory) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(int argc, WCHAR **argv) {
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
      wcout << L"LocalFree (" << GetLastError() << L") fatal error." <<endl;
  };

  auto getbaseaddress = [&getlasterror](DWORD pid) -> PBYTE {
    HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pid);
    if (INVALID_HANDLE_VALUE == snap) {
      getlasterror(0L);
      return nullptr;
    }

    MODULEENTRY32 mod = {0};
    mod.dwSize = sizeof(mod);
    if (!Module32First(snap, &mod)) getlasterror(0L);
    if (!CloseHandle(snap)) getlasterror(0L);

    return !mod.modBaseAddr ? nullptr : mod.modBaseAddr;
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  wstring app(argv[0]);
  app = app.substr(app.find_last_of(L"\\") + 1, app.length());
  if (2 != argc) {
    wcout << L"Usage: " << app << L" <PID>" <<endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
    PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, wcstoul(argv[1], 0, 0)
  )), [&getlasterror](HANDLE *instance) {
    if (*instance) {
      if (!CloseHandle(*instance)) getlasterror(0L);
      else wcout << L"[*] successfully released" << endl;
    }
  });

  if (!*ps) {
    getlasterror(0L);
    return 1;
  }
  // image base address
  PBYTE img = getbaseaddress(wcstoul(argv[1], 0, 0));
  if (nullptr == img) return 1;
  // locating PEB
  MEMORY_BASIC_INFORMATION mbi = {0};
  PVOID ptr = reinterpret_cast<PVOID>(0x7FFE0000); // lower than KUSER_SHARED_DATA
  while (1) {
    NTSTATUS nts = NtQueryVirtualMemory(
      *ps, ptr, MemoryBasicInformation, &mbi, sizeof(mbi), nullptr
    );
    if (!NT_SUCCESS(nts)) break;

    ptr = static_cast<PBYTE>(mbi.BaseAddress) + mbi.RegionSize;
    if (MEM_PRIVATE != mbi.Type
        && MEM_COMMIT != mbi.State
          && PAGE_READWRITE != mbi.Protect
    ) continue;

    PBYTE test{};
    nts = NtReadVirtualMemory(
      *ps, static_cast<PBYTE>(mbi.BaseAddress) + PebImgBase, &test, sizeof(PBYTE), nullptr
    );
    if (!NT_SUCCESS(nts)) {
      // getlasterror(nts);
      continue;
    }

    if (test == img) {
      wcout << L"[*] PEB address " << mbi.BaseAddress << endl;
      break;
    }
  }

  return 0;
}
