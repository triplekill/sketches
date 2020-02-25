from ctypes   import byref, windll
from ntrtl    import RtlNtStatusToDosError
from wintypes import DWORD, HLOCAL, LPCVOID, NTSTATUS, PWSTR, ULONG, va_list
# ====================================================================================
FORMAT_MESSAGE_ALLOCATE_BUFFER = DWORD(0x00000100).value
FORMAT_MESSAGE_FROM_SYSTEM     = DWORD(0x00001000).value
LANG_NEUTRAL                   = DWORD(0x00000000).value
SUBLANG_DEFAULT                = DWORD(0x00000001).value
# ====================================================================================
FormatMessage = windll.kernel32.FormatMessageW
FormatMessage.restype  = DWORD
# FormatMessage.argtypes = [DWORD, LPCVOID, DWORD, DWORD, LPTSTR, DWORD, va_list]
FormatMessage.argtypes = [DWORD, LPCVOID, DWORD, DWORD, HLOCAL, DWORD, va_list]

GetLastError = windll.kernel32.GetLastError
GetLastError.restype  = DWORD
GetLastError.argtypes = []

LocalFree = windll.kernel32.LocalFree
LocalFree.restype  = HLOCAL
LocalFree.argtypes = [HLOCAL]

LsaNtStatusToWinError = windll.advapi32.LsaNtStatusToWinError
LsaNtStatusToWinError.restype  = ULONG
LsaNtStatusToWinError.argtypes = [NTSTATUS]
# ====================================================================================
def getlasterror(fn):
   def MAKELANGID(p, s):
      return ULONG((s << 10) | p)
   def wrapper(*args):
      if len(args) >= 2:
         raise TypeError(
            '{0} takes 1 positional argument but {1} was given'.format(
               fn.__name__, # function name
               len(args)    # number of parameters
            )
         )
      err = fn() if not len(args) else fn(args[0])
      msg = HLOCAL()
      FormatMessage(
         FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, None,
         err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), byref(msg), 0, None
      )
      err = PWSTR(msg.value).value
      LocalFree(msg)
      print(err.strip() if err else 'Unknown error has been occured.')
   return wrapper

@getlasterror
def GetWin32Error() -> DWORD:
   return GetLastError()

@getlasterror
def GetNtError(nts : NTSTATUS) -> DWORD:
   return RtlNtStatusToDosError(nts)

@getlasterror
def GetLsaError(nts : NTSTATUS) -> DWORD:
   return LsaNtStatusToWinError(nts)
