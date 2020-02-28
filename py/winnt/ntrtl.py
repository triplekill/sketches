import wintypes as nt

from ctypes import windll
# ====================================================================================
RtlNtStatusToDosError = windll.ntdll.RtlNtStatusToDosError
# ====================================================================================
class RTL_TIME_ZONE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 172
      ('Bias',          nt.LONG),
      ('StandardName',  nt.WCHAR * 32),
      ('StandardStart', nt.TIME_FIELDS),
      ('StandardBias',  nt.LONG),
      ('DaylightName',  nt.WCHAR * 32),
      ('DaylightStart', nt.TIME_FIELDS),
      ('DaylightBias',  nt.LONG),
   )
# ====================================================================================
RtlNtStatusToDosError.restype  = nt.ULONG
RtlNtStatusToDosError.argtypes = [nt.NTSTATUS]
