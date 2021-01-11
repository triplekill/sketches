#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <string>
#include <memory>
#include <locale>

/*
 * It's possible to extract this information only with Debugging Tools.
 * >> cdb -z %__appdir__%drivers\hwpolicy.sys
 * Resource has fixed length (0x3da0):
 * >> .shell -ci "!showresources" sed "/3da0/!d"
 * The Name (.e.g. 0xa528) of the resource is the offset to the XSAVE_POLICY:
 * >> r @$t0 = hwpolicy + 0xa528
 * >> dx Debugger.Utility.Analysis.SynteticTypes.ReadHeader("E:\\sndbox\\xsave.h", "hwpolicy")
 * >> dx Debugger.Utility.Analysis.SynteticTypes.CreateInstance("XSAVE_POLICY", @$t0)
 * For showing Vendors:
 * >> dx Debugger.Utility.Analysis.SynteticTypes.CreateInstance("XSAVE_POLICY", @$t0).Features[0]
 * >> dx (char *)Debugger.Utility.Analysis.SynteticTypes.CreateInstance("XSAVE_VENDORS", (@$t0+0x410)).Vendor[0].VendorId
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
