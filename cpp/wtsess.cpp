#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <wtsapi32.h>
#include <cstdio>
#include <vector>
#include <locale>

#define T(x) L#x,
#define WTState T(Active) T(Connected) T(ConnectQuery) T(Shadow) \
        T(Disconnected) T(Idle) T(Listen) T(Reset) T(Down) T(Init)

#pragma comment (lib, "wtsapi32.lib")

int wmain(void) {
  using namespace std;

  locale::global(locale(""));
  auto getlasterror = []() {
    vector<wchar_t> buf(0x100);
    wprintf(L"%s\n", 0 != ::FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
      FORMAT_MESSAGE_MAX_WIDTH_MASK, nullptr, ::GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), &buf[0], 0x100, nullptr
    ) ? &buf[0] : L"Unknown error has been occured.");
  };

  DWORD lvl = 1, count{};
  PWTS_SESSION_INFO_1 inf;
  if (!::WTSEnumerateSessionsEx(nullptr, &lvl, 0, &inf, &count)) {
    getlasterror();
    return 1;
  }

  const wchar_t *state[] = { WTState };
  for (DWORD i = 0; i < count; i++) {
    auto& s = inf[i];
    wprintf(L"Session %d (%s)\nUser name: %s\\%s\nState: %s\n\n",
      s.SessionId, s.pSessionName,
      s.pDomainName ? s.pDomainName : L"NT AUTHORITY",
      s.pUserName ? s.pUserName : L"SYSTEM", state[s.State]
    );
  }

  ::WTSFreeMemory(inf);

  return 0;
}
