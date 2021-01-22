#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <locale>

#pragma comment (lib, "advapi32.lib")

void getlasterror(DWORD ecode) {
  HLOCAL loc{};
  DWORD size = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    nullptr, ecode, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    reinterpret_cast<LPWSTR>(&loc), 0, nullptr
  );

  if (!size)
    std::wcout << L"[?] Unknown error has been occured." << std::endl;
  else {
    std::wstring msg(reinterpret_cast<LPWSTR>(loc));
    std::wcout << L"[!] " << msg.substr(0, size - sizeof(wchar_t)) << std::endl;
  }

  if (nullptr != LocalFree(loc))
    std::wcout << L"LocalFree (" << GetLastError() << L") fatal error." << std::endl;
}

class CRegHelper {
  private:
    HKEY c_key;
  public:
    static HKEY openkey(const std::wstring &r_key) {
      LSTATUS status = ERROR_SUCCESS;
      static const struct {
         const wchar_t *name;
         const wchar_t *fullname;
         HKEY          key;
      } roots[] = {
         L"HKCR", L"HKEY_CLASSES_ROOT",   HKEY_CLASSES_ROOT,
         L"HKLM", L"HKEY_LOCAL_MACHINE",  HKEY_LOCAL_MACHINE,
         L"HKCU", L"HKEY_CURRENT_USER",   HKEY_CURRENT_USER,
         L"HKU",  L"HKEY_USERS",          HKEY_USERS,
         L"HKCC", L"HKEY_CURRENT_CONFIG", HKEY_CURRENT_CONFIG
      };

      HKEY key = nullptr;
      std::wstring root = r_key.substr(0, r_key.find_first_of(L"\\"));
      std::wstring path = r_key.substr(r_key.find_first_of(L"\\") + 1, r_key.length());
      for (int i = 0; i < sizeof(roots) / sizeof(roots[0]); i++) {
        if (0 == _wcsicmp(root.c_str(), roots[i].name) ||
            0 == _wcsicmp(root.c_str(), roots[i].fullname)) {
          status = RegOpenKeyEx(roots[i].key, path.c_str(), 0, KEY_QUERY_VALUE, &key);
          if (ERROR_SUCCESS != status) getlasterror(status);
          break;
        }
      }

      return key;
    }

    CRegHelper(const std::wstring &r_key) { c_key = openkey(r_key); }

    CRegHelper(const CRegHelper&) = delete;
    CRegHelper& operator=(const CRegHelper&) = delete;

    ~CRegHelper() {
      if (nullptr != c_key) {
        LSTATUS status = RegCloseKey(c_key);
        if (ERROR_SUCCESS != status)
          getlasterror(status);
        else
          std::wcout << L"[*] success" << std::endl;
      }
    }

    operator HKEY()   { return c_key; }
    HKEY* operator&() { return &c_key; }
};

int wmain(int argc, wchar_t **argv) {
  std::locale::global(std::locale(""));
  if (2 != argc) {
    std::wcout << L"[!] Index is out of range." << std::endl;
    return 1;
  }

  std::wstring key(argv[1]);
  CRegHelper rk(key);
  FILETIME ft = {0};
  SYSTEMTIME st = {0};

  LSTATUS status = RegQueryInfoKey(
    rk, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr,
    nullptr, nullptr, nullptr, nullptr, &ft
  );
  if (ERROR_SUCCESS != status) {
    getlasterror(status);
    return 1;
  }

  if (!FileTimeToLocalFileTime(&ft, &ft)) {
    getlasterror(GetLastError());
    return 1;
  }
  if (!FileTimeToSystemTime(&ft, &st)) {
    getlasterror(GetLastError());
    return 1;
  }

  std::wcout << L"[*] " << std::setfill(L'0') << std::setw(2) << st.wMonth << L"/"
                        << std::setfill(L'0') << std::setw(2) << st.wDay << L"/"
                        << st.wYear << L" "
                        << std::setfill(L'0') << std::setw(2) << st.wHour << L":"
                        << std::setfill(L'0') << std::setw(2) << st.wMinute << L":"
                        << std::setfill(L'0') << std::setw(2) << st.wSecond << std::endl;

  return 0;
}
