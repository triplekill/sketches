from ctypes import (
   POINTER, Structure, Union, c_char, c_long, c_longlong, c_short, c_size_t, c_ubyte, c_ulong, c_ulonglong, c_ushort, c_void_p, c_wchar_p, sizeof
)
from enum   import IntEnum
# ====================================================================================
CCHAR     = CHAR      = c_char
CSHORT    = SHORT     = c_short
DWORD     = ULONG     = c_ulong
HANDLE    = HLOCAL    = LPCVOID  = LPVOID = PVOID = va_list = c_void_p
LONG      = KPRIORITY = NTSTATUS = c_long
LONGLONG  = c_longlong
PWSTR     = c_wchar_p
SIZE_T    = c_size_t
ULONGLONG = c_ulonglong
ULONG_PTR = c_ulonglong if 8 == sizeof(c_void_p) else c_ulong
UCHAR     = c_ubyte
USHORT    = c_ushort
# ====================================================================================
PCHAR  = PSTR = POINTER(CHAR)
PULONG = POINTER(ULONG)
# ====================================================================================
class CEnum(IntEnum):
   @classmethod
   def from_param(cls, self):
      if not isinstance(self, cls):
         raise TypeError
      return self

class CStruct(Structure):
   @property
   def size(self):
      return ULONG(sizeof(self))
# ====================================================================================
class CLIENT_ID(Structure):
   _fields_ = (
      ('UniqueProcess', HANDLE),
      ('UniqueThread',  HANDLE),
   )

class LARGE_INTEGER_UNION(Structure):
   _fields_ = (
      ('LowPart',  ULONG),
      ('HighPart', LONG),
   )

class LARGE_INTEGER(Union):
   _fields_ = ( # LARGE_INTEGER = c_longlong
      ('u1',       LARGE_INTEGER_UNION),
      ('u2',       LARGE_INTEGER_UNION),
      ('QuadPart', LONGLONG),
   )

class UNICODE_STRING(Structure):
   _fields_ = (
      ('Length',        USHORT),
      ('MaximumLength', USHORT),
      ('Buffer',        PWSTR),
   )
LSA_UNICODE_STRING = UNICODE_STRING
