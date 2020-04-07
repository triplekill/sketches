#ifndef UNICODE
  #define UNICODE
#endif
//////////////////////////////////////////////////////////////////////////////////////
#include <windows.h>
#include <iostream>
#include <vector>
#include <locale>
//////////////////////////////////////////////////////////////////////////////////////
typedef LONG NTSTATUS;

#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) (reinterpret_cast<T>( \
                         GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1])))))
//////////////////////////////////////////////////////////////////////////////////////
typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef NTSTATUS (__stdcall *pNtQueryDefaultLocale)(
   BOOLEAN ThreadOrSystem, // TRUE - thread, FALSE - system
   PLCID Locale
);

typedef NTSTATUS (__stdcall *pRtlLcidToLocaleName)(
   LCID Locale,
   PUNICODE_STRING LocaleName,
   ULONG Flags, // reserved
   BOOLEAN AllocateDestinationString
);

typedef ULONG (__stdcall *pRtlNtStatusToDosError)(
   NTSTATUS Status
);

typedef VOID (__stdcall *pRtlFreeUnicodeString)(
   PUNICODE_STRING UnicodeString
);
//////////////////////////////////////////////////////////////////////////////////////
pNtQueryDefaultLocale NtQueryDefaultLocale;
pRtlLcidToLocaleName RtlLcidToLocaleName;
pRtlNtStatusToDosError RtlNtStatusToDosError;
pRtlFreeUnicodeString RtlFreeUnicodeString;
//////////////////////////////////////////////////////////////////////////////////////
BOOLEAN LocateSignatures(void) {
  NtQueryDefaultLocale = AddrToFunc(pNtQueryDefaultLocale);
  if (nullptr == NtQueryDefaultLocale) return FALSE;

  RtlLcidToLocaleName = AddrToFunc(pRtlLcidToLocaleName);
  if (nullptr == RtlLcidToLocaleName) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  RtlFreeUnicodeString = AddrToFunc(pRtlFreeUnicodeString);
  if (nullptr == RtlFreeUnicodeString) return FALSE;

  return TRUE;
}

int wmain(void) {
  using std::endl;
  using std::hex;
  using std::locale;
  using std::vector;
  using std::wcout;

  locale::global(locale(""));
  auto getlasterror = [](NTSTATUS nts) {
    vector<wchar_t> msg(0x100);
    DWORD sz = static_cast<DWORD>(msg.size());
    wcout << (!FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
      FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr,
      0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &msg[0], sz, nullptr
    ) ? L"Unknown error has been occured." : &msg[0]) << endl;
  };

  if (!LocateSignatures()) {
    getlasterror(0L);
    return 1;
  }

  LCID lcid{};
  NTSTATUS nts = NtQueryDefaultLocale(FALSE, &lcid);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }

  UNICODE_STRING name;
  nts = RtlLcidToLocaleName(lcid, &name, 0, TRUE);
  if (!NT_SUCCESS(nts)) {
    getlasterror(nts);
    return 1;
  }
  wcout << name.Buffer << L" : 0x" << hex << lcid << endl;
  RtlFreeUnicodeString(&name);

  return 0;
}
