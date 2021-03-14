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

#include <iostream>
#include <iomanip>
#include <string>
#include <memory>
#include <vector>
#include <regex>

#pragma comment(lib, "ntdll.lib")

#define LastWin32 (0)
#define Winsock2 L"winsock2\\\\catalogchangelistener-(.+)-0"
#define WmiEvent L"pipe_eventroot\\\\cimv2scm event provider"
#define Chromium L".*mojo\\.(\\d+)\\.\\d+\\.\\d+"
#define MsysPipe L"msys-\\S+-(\\d+)-\\S+"

template<typename T, bool (*Cleanup)(T)>
struct AutoHelper {
  using pointer = T;

  void operator()(T t) const {
    if (!Cleanup(t))
      std::wcout << L"[!] err: 0x"
                 << std::hex
                 << ::GetLastError()
                 << std::endl;
#ifdef DEBUG
    else
      std::wcout << L"[*] successfully released" << std::endl;
#endif
  }
};

bool AutoHandle(const HANDLE h) { return ::CloseHandle(h); }
bool AutoLocals(const HLOCAL h) { return nullptr == ::LocalFree(h); }

#endif
