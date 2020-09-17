#ifndef _LSPIPE
#define _LSPIPE

#pragma once

#ifndef UNICODE
  #define UNICODE
#endif

#ifndef WIN32_LEAN_AND_MEAN
  #define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#include <ntapi.h>
#include <aclapi.h>

#include <iostream>
#include <iomanip>
#include <string>
#include <memory>
#include <vector>

#pragma comment (lib, "advapi32.lib")
#pragma comment (lib, "ntdll.lib")

#define LAST (0)

template<typename T, bool (*Cleanup)(T)>
struct CHelper {
  using pointer = T;

  void operator()(T t) const {
    if (!Cleanup(t))
      std::wcout << L"[!] err: 0x" << std::hex
                 << ::GetLastError() << std::endl;
    //else
    //  std::wcout << L"[*] success" << std::endl;
  }
};

bool ClrHandle(const HANDLE h) { return ::CloseHandle(h); }
bool ClrLocal(const HLOCAL h) { return nullptr == ::LocalFree(h); }

#endif
