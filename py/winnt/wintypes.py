from ctypes import (
   POINTER, Structure, Union, c_char, c_byte, c_long, c_longlong, c_short, c_size_t,
   c_ubyte, c_ulong, c_ulonglong, c_ushort, c_void_p, c_wchar, c_wchar_p, sizeof
)
from enum   import IntEnum
# ====================================================================================
ACCESS_MASK = DWORD     = ULONG = c_ulong
CCHAR       = CHAR      = c_char
CSHORT      = SHORT     = c_short
BOOLEAN     = BYTE      = c_byte
HANDLE      = HLOCAL    = LPCVOID  = PVOID = va_list = c_void_p
KAFFINITY   = ULONG_PTR = c_ulonglong if 8 == sizeof(c_void_p) else c_ulong
LONG        = KPRIORITY = NTSTATUS = c_long
LONGLONG    = c_longlong
PWSTR       = c_wchar_p
SIZE_T      = c_size_t
ULONGLONG   = c_ulonglong
UCHAR       = c_ubyte
USHORT      = WORD      = c_ushort
WCHAR       = c_wchar
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
LOGICAL_PROCESSOR_RELATIONSHIP = IntEnum('LOGICAL_PROCESSOR_RELATIONSHIP', (
   'RelationProcessorCore',
   'RelationNumaNode',
   'RelationCache',
   'RelationProcessorPackage',
   'RelationGroup',
   'RelationAll', # 0xffff
), start=0)

PROCESSOR_CACHE_TYPE = IntEnum('PROCESSOR_CACHE_TYPE', (
   'CacheUnified',
   'CacheInstruction',
   'CacheData',
   'CacheTrace',
), start=0)
# ====================================================================================
class CACHE_DESCRIPTOR(Structure):
   _fields_ = (
      ('Level',         BYTE),
      ('Associativity', BYTE),
      ('LineSize',      WORD),
      ('Size',          DWORD),
      ('_Type',         DWORD),
   )
   @property
   def Type(self):
      return PROCESSOR_CACHE_TYPE(self._Type).name if self._Type else None

class CLIENT_ID(Structure):
   _fields_ = (
      ('UniqueProcess', HANDLE),
      ('UniqueThread',  HANDLE),
   )

class GENERIC_MAPPING(Structure):
   _fields_ = (
      ('GenericRead',    ACCESS_MASK),
      ('GenericWrite',   ACCESS_MASK),
      ('GenericExecute', ACCESS_MASK),
      ('GenericAll',     ACCESS_MASK)
   )

class GROUP_AFFINITY(Structure):
   _fields_ = (
      ('Mask',     KAFFINITY),
      ('Group',    USHORT),
      ('Reserved', USHORT * 3),
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

class NUMANODE(Structure):
   _fields_ = (
      ('NodeNumber', ULONG),
   )

class PROCESSORCORE(Structure):
   _fields_ = (
      ('Flags', BYTE),
   )

class TIME_FIELDS(Structure):
   _fields_ = (
      ('Year',         CSHORT),
      ('Month',        CSHORT),
      ('Day',          CSHORT),
      ('Hour',         CSHORT),
      ('Minute',       CSHORT),
      ('Second',       CSHORT),
      ('Milliseconds', CSHORT),
      ('Weekday',      CSHORT),
   )

class UNICODE_STRING(Structure):
   _fields_ = (
      ('Length',        USHORT),
      ('MaximumLength', USHORT),
      ('Buffer',        PWSTR),
   )
LSA_UNICODE_STRING = UNICODE_STRING

class OBJECT_NAME_INFORMATION(Structure):
   _fields_ = (
      ('Name', UNICODE_STRING),
   )
