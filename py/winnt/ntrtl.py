import wintypes as nt

from ctypes import windll
# ====================================================================================
RtlNtStatusToDosError = windll.ntdll.RtlNtStatusToDosError
RtlNtStatusToDosError.restype  = nt.ULONG
RtlNtStatusToDosError.argtypes = [nt.NTSTATUS]
