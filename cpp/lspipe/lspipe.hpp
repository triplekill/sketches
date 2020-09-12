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

// INVALID_HANDLE_VALUE wrapper
class CHandle {
  public:
    CHandle() = default;
    CHandle(std::nullptr_t) {}
    CHandle(HANDLE h) : h(h) {}

  operator HANDLE() const { return h; }

  friend bool operator ==(const CHandle &l, const CHandle &r) {
    return l.h == r.h;
  }
  friend bool operator !=(const CHandle &l, const CHandle &r) {
    return l.h != r.h;
  }

  private:
    HANDLE h = INVALID_HANDLE_VALUE;
};

void getrawerror(void) {
  std::wcout << L"[!] err: 0x" << std::hex
             << ::GetLastError() << std::endl;
}

struct HandleHelper {
  using pointer = CHandle;

  void operator()(pointer p) const {
    if (!::CloseHandle(p)) getrawerror();
    //else std::wcout << L"[*] closed" << std::endl;
  }
};

template<typename T>
struct LocalHelper {
  using pointer = T;

  void operator()(T t) const {
    if (nullptr != ::LocalFree(t)) getrawerror();
    //else std::wcout << L"[*] freed" << std::endl;
  }
};

#endif
