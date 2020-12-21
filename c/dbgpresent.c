#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <winternl.h> // PEB
#include <intrin.h>
#include <stdio.h>
#include <locale.h>

/*
 * ntdll!RtlIsAnyDebuggerPresent
 * __asm { // x64 and x86 only
 * #ifdef _M_X64
 *   mov  rax, qword ptr gs:[60h]             ; PEB
 *   mov  al, byte ptr [rax+2]                ; PEB->BeingDebugged
 *   test al, al
 *   jne  ntdll!RtlIsAnyDebuggetPresent+0x1e
 * #else
 *   mov  eax, dword ptr fs:[30h]
 *   mov  al, byte ptr [eax+2]
 *   test al, al
 *   jne  ntdll!RtlIsAnyDebuggetPresent+0x19
 * #endif
 *   mov  al, byte ptr [SharedUserData+0x2d4] ; KUSER_SHARED_DATA->KeDebuggerEnabled
 *   and  al, 3
 *   cmp  al, 3
 *   sete al
 *   ret
 * }
 *
 * Conclusion
 *   The following instruction should be work in both 32 and 64-bit applications:
 *   cmp byte ptr ds:[7ffe02d4], 3
 */

void PrintErrMessage(void) {
  HLOCAL msg = NULL;
  DWORD size = FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
    NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
    (LPWSTR)&msg, 0, NULL
  );
  if (0 == size)
    wprintf(L"[?] Unknown error has been occured.\n");
  else
    wprintf(L"[!] %.*s\n", (LONG)(size - sizeof(WCHAR)), (LPWSTR)msg);

  if (NULL != LocalFree(msg))
    wprintf(L"LocalFree (%d) fatal error.\n", GetLastError());
}

void PrintResult(PWSTR msg, BOOL result) {
  wprintf(L"%s: %s\n", msg, result ? L"true" : L"false");
}

/*
 * IsDebuggerPresent extracts information about attached debugger through
 * PEB. The function below describes two possible techniques to do same
 * without WinAPI usage.
 */
BOOL IsDebugged(void) {
#ifdef __clang__
  BOOL res = FALSE;
  __asm {
  #ifdef _M_X64
    mov   rax, qword ptr gs:[0x60]
    movzx eax, byte ptr [rax+2]
  #else
    mov   eax, dword ptr fs:[0x30]
    movzx eax, byte ptr [eax+2]
  #endif
    mov   res, eax
  }
  return res;
#elif _MSC_VER
  // or use RtlGetCurrentPeb
  PPEB peb = NULL;
  #ifdef _M_X64
    peb = (PPEB)__readgsqword(0x60);
  #else
    peb = (PPEB)__readfsdword(0x30);
  #endif
  return peb->BeingDebugged;
#else
  return IsDebuggerPresent();
#endif
}

/*
 * Yet another approatch detecting attached debugger through PEB. The next
 * flags should be checked:
 * FLG_HEAP_ENABLE_FREE_CHECK
 * FLG_HEAP_ENABLE_TAIL_CHECK
 * FLG_HEAP_VALIDATE_PARAMETERS
 */
BOOL CheckNtGlobalFlags(void) {
  ULONG flags = 0;
#ifdef __clang__
  __asm {
  #ifdef _M_X64
    mov   rax, qword ptr gs:[0x60]
    movzx eax, byte ptr [rax+0xBC]
  #else
    mov   eax, dword ptr fs:[0x30]
    movzx eax, byte ptr [eax+0x68]
  #endif
    mov   flags, eax
  }
#elif _MSC_VER
  PPEB peb = NULL;
  #ifdef _M_X64
    peb = (PPEB)__readgsqword(0x60);
    flags = *(ULONG *)((PBYTE)peb + 0xBC);
  #else
    peb = (PPEB)__readfsdword(0x30);
    flags = *(ULONG *)((PBYTE)peb + 0x68);
  #endif
#endif
  return (0 != (flags & 0x70));
}

int wmain(void) {
  _wsetlocale(LC_CTYPE, L"");

  BOOL res = FALSE;
  PrintResult(L"IsDebuggerPresent", IsDebugged());
  if (!CheckRemoteDebuggerPresent(GetCurrentProcess(), &res))
    PrintErrMessage();
  else
    PrintResult(L"CheckRemoteDebuggerPresent", res);
  PrintResult(L"CheckNtGlobalFlags", CheckNtGlobalFlags());

  return 0;
}
