#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <iomanip>
#include <vector>
#include <locale>

typedef LONG NTSTATUS;

#define DIRECTORY_QUERY 0x0001
#define STATUS_MORE_ENTRIES (static_cast<NTSTATUS>(0x00000105L))
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>(GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))

typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct _OBJECT_DIRECTORY_INFORMATION {
   UNICODE_STRING Name;
   UNICODE_STRING TypeName;
} OBJECT_DIRECTORY_INFORMATION, *POBJECT_DIRECTORY_INFORMATION;

typedef struct _OBJECT_ATTRIBUTES {
   ULONG           Length;
   HANDLE          RootDirectory;
   PUNICODE_STRING ObjectName;
   ULONG           Attributes;
   PVOID           SecurityDescriptor;
   PVOID           SecurityQualityOfSevice;
} OBJECT_ATTRIBUTES, *POBJECT_ATTRIBUTES;

typedef NTSTATUS (__stdcall *pNtOpenDirectoryObject)(PHANDLE, ACCESS_MASK, POBJECT_ATTRIBUTES);
typedef NTSTATUS (__stdcall *pNtQueryDirectoryObject)(HANDLE, PVOID, ULONG, BOOLEAN, BOOLEAN, PULONG, PULONG);
typedef VOID     (__stdcall *pRtlInitUnicodeString)(PUNICODE_STRING, PCWSTR);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtOpenDirectoryObject NtOpenDirectoryObject;
pNtQueryDirectoryObject NtQueryDirectoryObject;
pRtlInitUnicodeString RtlInitUnicodeString;
pRtlNtStatusToDosError RtlNtStatusToDosError;

#define InitializeObjectAttributes(p, n, a, r, s) { \
   (p)->Length = sizeof(OBJECT_ATTRIBUTES); \
   (p)->RootDirectory = r; \
   (p)->Attributes = a; \
   (p)->ObjectName = n; \
   (p)->SecurityDescriptor = s; \
   (p)->SecurityQualityOfSevice = nullptr; \
};

BOOLEAN LocateSignatures(void) {
  NtOpenDirectoryObject = AddrToFunc(pNtOpenDirectoryObject);
  if (nullptr == NtOpenDirectoryObject) return FALSE;

  NtQueryDirectoryObject = AddrToFunc(pNtQueryDirectoryObject);
  if (nullptr == NtQueryDirectoryObject) return FALSE;

  RtlInitUnicodeString = AddrToFunc(pRtlInitUnicodeString);
  if (nullptr == RtlInitUnicodeString) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

struct HndlCloser {
  using pointer = HANDLE;

  void operator ()(HANDLE instance) const {
    std::wcout << (
      CloseHandle(instance) ?
        L"[*] Resources has been released." :
        L"[!] CloseHandle failed."
    ) << std::endl;
  }
};

int wmain(void) {
  std::locale::global(std::locale(""));
  auto PrintErrMessage = [](NTSTATUS nts) {
    std::vector<wchar_t> msg(0x100);
    DWORD sz = static_cast<DWORD>(msg.size());
    std::wcout << L"[!] " << (!FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
      FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr,
      0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &msg[0], sz, nullptr
    ) ? L"Unknown error has been occured." : &msg[0]) << std::endl;
  };

  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  OBJECT_ATTRIBUTES oa;
  //UNICODE_STRING path = {20, 22, L"\\KnownDlls"};
  UNICODE_STRING path;
  RtlInitUnicodeString(&path, L"\\KnownDlls");
  InitializeObjectAttributes(&oa, &path, 0, nullptr, nullptr);

  HANDLE hndl{};
  NTSTATUS nts = NtOpenDirectoryObject(&hndl, DIRECTORY_QUERY, &oa);
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }
  std::unique_ptr<HANDLE, HndlCloser> KnownDlls(hndl);
  std::wcout << L"[*] KnownDlls success opening." << std::endl;

  ULONG bsz = 0x100, items = 0, bytes = 0;
  std::vector<OBJECT_DIRECTORY_INFORMATION> buf(bsz);
  while (STATUS_MORE_ENTRIES == NtQueryDirectoryObject(
    KnownDlls.get(), &buf[0], bsz, FALSE, TRUE, &items, &bytes
  )) {
    bsz += bytes;
    buf.resize(bsz);
  }

  std::wcout << L"No Type          Name\n-- -----         -----" << std::endl;
  for (ULONG i = 0; i < items; i++)
    std::wcout <<
      std::right << std::setw(2) << i + 1 << L" " <<
      std::left << std::setw(13) << buf[i].TypeName.Buffer << L" " <<
      buf[i].Name.Buffer << std::endl;
  std::vector<OBJECT_DIRECTORY_INFORMATION> ().swap(buf);

  return 0;
}
