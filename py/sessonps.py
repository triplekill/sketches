# -*- coding: utf-8 -*-
from ctypes import (
   POINTER, Structure, Union, addressof, byref, cast, create_string_buffer, c_long,
   c_longlong, c_ulong, c_size_t, c_ulonglong, c_ushort, c_void_p, c_wchar_p, sizeof,
   windll
)
from sys    import exit

SystemSessionProcessInformation = c_ulong(53)
UINT_PTR = c_ulonglong if 8 == sizeof(c_void_p) else c_ulong
STATUS_SUCCESS = c_long(0x00000000).value
STATUS_INFO_LENGTH_MISMATCH = c_long(0xC0000004).value

NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
NtQuerySystemInformation.restype = c_long
NtQuerySystemInformation.argtypes = (c_ulong, c_void_p, c_ulong, POINTER(c_ulong))

RtlNtStatusToDosError = windll.ntdll.RtlNtStatusToDosError
RtlNtStatusToDosError.restype = c_ulong
RtlNtStatusToDosError.argtype = c_long

FormatMessage = windll.kernel32.FormatMessageW
FormatMessage.restype = c_ulong
FormatMessage.argtypes = (c_ulong, c_void_p, c_ulong, c_ulong, c_void_p, c_ulong, c_void_p)

LocalFree = windll.kernel32.LocalFree
LocalFree.restype = c_void_p
LocalFree.argtype = c_void_p

class SYSTEM_SESSION_PROCESS_INFORMATION(Structure):
   _fields_ = (
      ('SessionId', c_ulong),
      ('SizeOfBuf', c_ulong),
      ('Buffer',    c_void_p),
   )

class UNICODE_STRING(Structure):
   _fields_ = (
      ('Length',        c_ushort),
      ('MaximumLength', c_ushort),
      ('Buffer',        c_wchar_p),
   )

class _LARGE_INTEGER_(Structure):
   _fields_ = (
      ('LowPart',  c_ulong),
      ('HighPart', c_long),
   )

class LARGE_INTEGER(Union):
   _fields_ = (
      ('u1',       _LARGE_INTEGER_),
      ('u2',       _LARGE_INTEGER_),
      ('QuadPart', c_longlong),
   )

class SYSTEM_PROCESS_INFORMATION(Structure):
   _fields_ = (
      ('NextEntryOffset',              c_ulong),
      ('NumberOfThreads',              c_ulong),
      ('WorkingSetPrivateState',       LARGE_INTEGER),
      ('HardFaultCount',               c_ulong),
      ('NumberOfThreadsHighWatermark', c_ulong),
      ('CycleTime',                    c_ulonglong),
      ('CreateTime',                   LARGE_INTEGER),
      ('UserTime',                     LARGE_INTEGER),
      ('KernelTime',                   LARGE_INTEGER),
      ('ImageName',                    UNICODE_STRING),
      ('BasePriority',                 c_long),
      ('UniqueProcessId',              c_void_p),
      ('InheritedFromUniqueProcessId', c_void_p),
      ('HandleCount',                  c_ulong),
      ('SessionId',                    c_ulong),
      ('UniqueProcessKey',             UINT_PTR),
      ('PeakVirtualSize',              c_size_t),
      ('VirtualSize',                  c_size_t),
      ('PageFaultCount',               c_ulong),
      ('PeakWorkingSetSize',           c_size_t),
      ('WorkingSetSize',               c_size_t),
      ('QuotaPeakPagedPoolUsage',      c_size_t),
      ('QuotaPagedPoolUsage',          c_size_t),
      ('QuotaPeakNonPagedPoolUsage',   c_size_t),
      ('QuotaNonPagedPoolUsage',       c_size_t),
      ('PagefileUsage',                c_size_t),
      ('PeakPagefileUsage',            c_size_t),
      ('PrivatePageCount',             c_size_t),
      ('ReadOperationCount',           LARGE_INTEGER),
      ('WriteOperationCount',          LARGE_INTEGER),
      ('OtherOperationCount',          LARGE_INTEGER),
      ('ReadTransferCount',            LARGE_INTEGER),
      ('WriteTransferCount',           LARGE_INTEGER),
      ('OtherTransferCount',           LARGE_INTEGER),
   )

def getlasterror(nts : c_long) -> None:
   msg, err = c_wchar_p(), RtlNtStatusToDosError(nts)
   print('Unknown error has been occured.'
      if not FormatMessage(
         0x1100, None, err, 0x400, byref(msg), 0, None
      ) else msg.value.strip()
   )
   if LocalFree(msg):
      print('LocalFree fatal error.')

if __name__ == '__main__':
   inf = SYSTEM_SESSION_PROCESS_INFORMATION()
   buf = create_string_buffer(0x1000)
   inf.SessionId = 1
   inf.SizeOfBuf = len(buf)
   inf.Buffer    = addressof(buf)

   ret = c_ulong(0)
   if STATUS_INFO_LENGTH_MISMATCH != (nts := NtQuerySystemInformation(
      SystemSessionProcessInformation, byref(inf), sizeof(inf), byref(ret)
   )):
       getlasterror(nts)
       exit(1)
   buf = create_string_buffer(ret.value)
   inf.SizeOfBuf = len(buf)
   inf.Buffer    = addressof(buf)
   if STATUS_SUCCESS != (nts := NtQuerySystemInformation(
      SystemSessionProcessInformation, byref(inf), sizeof(inf), byref(ret)
   )):
       getlasterror(nts)
       exit(1)
   adr = addressof(buf)
   spi = cast(adr, POINTER(SYSTEM_PROCESS_INFORMATION))
   while (spi[0].NextEntryOffset):
      print('{0:4}: {1}'.format(spi[0].UniqueProcessId, spi[0].ImageName.Buffer))
      adr += spi[0].NextEntryOffset
      spi = cast(adr, POINTER(SYSTEM_PROCESS_INFORMATION))
