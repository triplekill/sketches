# -*- coding: utf-8 -*-
__all__ = ['getcpubrandstring']

from ctypes import byref, create_unicode_buffer, c_ulong, windll

FormatMessage            = windll.kernel32.FormatMessageW
NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
RtlNtStatusToDosError    = windll.ntdll.RtlNtStatusToDosError

NtQuerySystemInformation.restype = c_ulong

def getlasterror(ntstatus):
   msg = create_unicode_buffer(0x100)
   print(msg.value if FormatMessage(
      0x12FF, None, RtlNtStatusToDosError(ntstatus), 1024, msg, len(msg), None
   ) else 'Unknown error has been occured.')

def getcpubrandstring():
   # KUSER_SHARED_DATA -> NtMajorVersion
   if 6 > c_ulong.from_address(0x7FFE026C).value:
      print('Sorry, but this requires Vista or higher.')
      return
   # SystemProcessorBrandString = 0n105
   req = c_ulong(0) # retrieve required buffer length
   nts = NtQuerySystemInformation(105, None, 0, byref(req))
   if 0xC0000004 != nts or 0 == req.value:
      getlasterror(nts)
      return
   buf = create_unicode_buffer(req.value)
   nts = NtQuerySystemInformation(105, buf, len(buf), None)
   if 0 != nts:
      getlasterror(nts)
      return
   return str(buf, 'utf-8')
