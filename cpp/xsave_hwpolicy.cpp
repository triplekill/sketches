#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <string>
#include <memory>
#include <locale>

/*
 * 0:000> .shell -ci "!dh -f hwpolicy" sed "/resource/I!d"
 *     A000 [    4470] address [size] of Resource Directory
 * .shell: Process exited
 *
 * 0:000> !showresources
 * ...
 * .  Name: a528  Data: 3da0
 * ...
 * 0:000> .reload /i /f ole32.dll
 * ...
 * 0:000> t @$t0 = hwpolicy + a528
 * 0:000> dx (ole32!XSAVE_POLICY *)@$t0
 * (ole32!XSAVE_POLICY *)@$t0                 : 0x1c000a528 [Type: XSAVE_POLICY *]
 *     [+0x000] Version          : 0x3 [Type: unsigned long]
 *     [+0x004] Size             : 0x3da0 [Type: unsigned long]
 *     [+0x008] Flags            : 0x9 [Type: unsigned long]
 *     [+0x00c] MaxSaveAreaLength : 0x2000 [Type: unsigned long]
 *     [+0x010] FeatureBitmask   : 0x7fffffffffffffff [Type: unsigned __int64]
 *     [+0x018] NumberOfFeatures : 0x3f [Type: unsigned long]
 *     [+0x020] Features         [Type: _XSAVE_FEATURE [1]]
 * 0:000> dx -r1 (*((ole32!_XSAVE_FEATURE (*)[1])0x1c000a548))
 * (*((ole32!_XSAVE_FEATURE (*)[1])0x1c000a548))                 [Type: _XSAVE_FEATURE [1]]
 *     [0]              [Type: _XSAVE_FEATURE]
 * 0:000> dx -r1 (*((ole32!_XSAVE_FEATURE *)0x1c000a548))
 * (*((ole32!_XSAVE_FEATURE *)0x1c000a548))                 [Type: _XSAVE_FEATURE]
 *     [+0x000] FeatureId        : 0x0 [Type: unsigned long]
 *     [+0x008] Vendors          : 0x410 [Type: _XSAVE_VENDORS *]
 *     [+0x008] Unused           : 0x410 [Type: unsigned __int64]
 * 0:000> dx -r1 ((ole32!_XSAVE_VENDORS *)0x410)
 * ((ole32!_XSAVE_VENDORS *)0x410)                 : 0x410 [Type: _XSAVE_VENDORS *]
 *     [+0x000] NumberOfVendors  : Unable to read memory at Address 0x410
 *     [+0x008] Vendor           [Type: _XSAVE_VENDOR [1]]
 * 0:000> 0:000> dx -r3 *((ole32!XSAVE_FEATURE (*)[0x3f])(@$t0 + 0x20))
 * *((ole32!XSAVE_FEATURE (*)[0x3f])(@$t0 + 0x20))                 [Type: XSAVE_FEATURE [63]]
 *    [0]              [Type: XSAVE_FEATURE]
 *        [+0x000] FeatureId        : 0x0 [Type: unsigned long]
 *        [+0x008] Vendors          : 0x410 [Type: _XSAVE_VENDORS *]
 *            [+0x000] NumberOfVendors  : Unable to read memory at Address 0x410
 *            [+0x008] Vendor           [Type: _XSAVE_VENDOR [1]]
 *        [+0x008] Unused           : 0x410 [Type: unsigned __int64]
 *    [1]              [Type: XSAVE_FEATURE]
 *        [+0x000] FeatureId        : 0x1 [Type: unsigned long]
 *        [+0x008] Vendors          : 0x520 [Type: _XSAVE_VENDORS *]
 *            [+0x000] NumberOfVendors  : Unable to read memory at Address 0x520
 *            [+0x008] Vendor           [Type: _XSAVE_VENDOR [1]]
 *        [+0x008] Unused           : 0x520 [Type: unsigned __int64]
 *    [2]              [Type: XSAVE_FEATURE]
 *        [+0x000] FeatureId        : 0x2 [Type: unsigned long]
 *        [+0x008] Vendors          : 0x630 [Type: _XSAVE_VENDORS *]
 *            [+0x000] NumberOfVendors  : Unable to read memory at Address 0x630
 *            [+0x008] Vendor           [Type: _XSAVE_VENDOR [1]]
 *        [+0x008] Unused           : 0x630 [Type: unsigned __int64]
 * ...
 * 0:000> dx (ole32!XSAVE_VENDORS *)(@$t0 + 0x410)
 * (ole32!XSAVE_VENDORS *)(@$t0 + 0x410)                 : 0x1c000a938 [Type: XSAVE_VENDORS *]
 *     [+0x000] NumberOfVendors  : 0x4 [Type: unsigned long]
 *     [+0x008] Vendor           [Type: _XSAVE_VENDOR [1]]
 * 0:000> dx -r1 (*((ole32!_XSAVE_VENDOR (*)[1])0x1c000a940))
 * (*((ole32!_XSAVE_VENDOR (*)[1])0x1c000a940))                 [Type: _XSAVE_VENDOR [1]]
 *     [0]              [Type: _XSAVE_VENDOR]
 * 0:000> dx -r1 (*((ole32!_XSAVE_VENDOR *)0x1c000a940))
 * (*((ole32!_XSAVE_VENDOR *)0x1c000a940))                 [Type: _XSAVE_VENDOR]
 *     [+0x000] VendorId         [Type: unsigned long [3]]
 *     [+0x010] SupportedCpu     [Type: _XSAVE_SUPPORTED_CPU]
 * 0:000> dx (char *)(*((ole32!unsigned long (*)[3])0x1c000a940))
 * (char *)(*((ole32!unsigned long (*)[3])0x1c000a940))                 : 0x1c000a940 : "GenuineIntel" [Type: char *]
 * 0:000> dx (*((ole32!XSAVE_VENDOR (*)[4])0x1c000a940)).Select(x => (char *)x.VendorId)
 * (*((ole32!_XSAVE_VENDOR (*)[4])0x1c000a940)).Select(x => (char *)x.VendorId)
 *     [0]              : 0x1c000a940 : "GenuineIntel" [Type: char *]
 *     [1]              : 0x1c000a978 : "AuthenticAMD" [Type: char *]
 *     [2]              : 0x1c000a9b0 : "CentaurHauls" [Type: char *]
 *     [3]              : 0x1c000a9e8 : "HygonGenuine" [Type: char *]
 * And so on.
 */
typedef struct _XSAVE_CPU_INFO {
   BYTE   Processor;
   USHORT Family;
   USHORT Model;
   USHORT Stepping;
   USHORT ExtendedModel;
   ULONG  ExtendedFamily;
   ULONGLONG MicrocodeVersion;
   ULONG  Reserved;
} XSAVE_CPU_INFO, *PXSAVE_CPU_INFO;

typedef struct _XSAVE_CPU_ERRATA {
   ULONG  NumberOfEntries;
   XSAVE_CPU_INFO Errata[1];
} XSAVE_CPU_ERRATA, *PXSAVE_CPU_ERRATA;

typedef struct _XSAVE_SUPPORTED_CPU {
   XSAVE_CPU_INFO CpuInfo;
   union {
      PXSAVE_CPU_ERRATA CpuErrata;
      ULONGLONG Unused;
   };
} XSAVE_SUPPORTED_CPU, *PXSAVE_SUPPORTED_CPU;

typedef struct _XSAVE_VENDOR {
   ULONG  VendorId[3];
   XSAVE_SUPPORTED_CPU SupportedCpu;
} XSAVE_VENDOR, *PXSAVE_VENDOR;

typedef struct _XSAVE_VENDORS {
   ULONG  NumberOfVendors;
   XSAVE_VENDOR Vendor[1];
} XSAVE_VENDORS, *PXSAVE_VENDORS;

typedef struct _XSAVE_FEATURE {
   ULONG  FeatureId;
   union {
      PXSAVE_VENDORS Vendors;
      ULONGLONG Unused;
   };
} XSAVE_FEATURE, *PXSAVE_FEATURE;

typedef struct _XSAVE_POLICY {
   ULONG  Version;
   ULONG  Size;
   ULONG  Flags;
   ULONG  MaxSaveAreaLength;
   ULONGLONG FeatureBitmask;
   ULONG  NumberOfFeatures;
   XSAVE_FEATURE Features[1];
} XSAVE_POLICY, *PXSAVE_POLICY;

int main(void) {
  using namespace std;

  locale::global(locale(""));
  auto getlasterror = []() {
    HLOCAL loc{};
    DWORD size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
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

  wstring sysfile(MAX_PATH - sizeof(L"\\drivers\\hwpolicy.sys"), L'\0');
  UINT len = GetSystemDirectory(&sysfile[0], sysfile.length());
  if (0 == len) {
    getlasterror();
    return 1;
  }
  sysfile = sysfile.substr(0, len) + L"\\drivers\\hwpolicy.sys";

  auto sys = shared_ptr<HMODULE>(new HMODULE(LoadLibraryEx(
    sysfile.c_str(), nullptr, LOAD_LIBRARY_AS_IMAGE_RESOURCE
  )), [&getlasterror](HMODULE *instance) {
    if (*instance) {
      if (!FreeLibrary(*instance)) getlasterror();
      else wcout << L"[*] success" << endl;
    }
  });

  if (!*sys) {
    getlasterror();
    return 1;
  }

  HRSRC fres = FindResource(*sys, MAKEINTRESOURCE(0x01), MAKEINTRESOURCE(0x65));
  if (nullptr == fres) {
    getlasterror();
    return 1;
  }

  HGLOBAL lres = LoadResource(*sys, fres);
  if (nullptr == lres) {
    getlasterror();
    return 1;
  }

  PXSAVE_POLICY xpol = static_cast<PXSAVE_POLICY>(LockResource(lres));
  wcout << hex << L"Version: 0x" << xpol->Version << L"\n"
               << L"Size: 0x" << xpol->Size << L"\n"
               << L"Flags: 0x" << xpol->Flags << L"\n"
               << L"MaxSaveAreaLength: 0x" << xpol->MaxSaveAreaLength << L"\n"
               << L"FeatureBitmask: 0x" << xpol->FeatureBitmask << L"\n"
               << L"NumberOfFeatures: 0x" << xpol->NumberOfFeatures << L"\n"
               << L"Features:" << endl;
  for (ULONG i = 0; i < xpol->NumberOfFeatures; i++) {
    wcout << L"\tFeature ID: " << xpol->Features[i].FeatureId << endl;

    wcout << L"\tVendors:" << endl;
    PXSAVE_VENDORS xven = reinterpret_cast<PXSAVE_VENDORS>(
      xpol->Features[i].Unused + reinterpret_cast<ULONG_PTR>(xpol)
    );
    for (ULONG j = 0; j < xven->NumberOfVendors; j++) {
      wcout << L"\t\tVendor ID: " << reinterpret_cast<PCHAR>(
            xven->Vendor[j].VendorId
          ) << endl;
    }
  }

  return 0;
}
