# -*- coding: utf-8 -*-
from ctypes import (
   byref, create_unicode_buffer, c_long, c_ulong, c_wchar_p, windll
)
from struct import unpack_from

STATUS_BUFFER_TO_SMALL = c_long(0xC0000023).value

FormatMessage            = windll.kernel32.FormatMessageW
GetLastError             = windll.kernel32.GetLastError
NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
RtlNtStatusToDosError    = windll.ntdll.RtlNtStatusToDosError

NtQuerySystemInformation.restype = c_long

def getlasterror(nts):
   msg = create_unicode_buffer(0x100)
   print('Unknown error has been occured.'
      if not FormatMessage(
         0x12FF, None,
         RtlNtStatusToDosError(nts) if 0 != nts else GetLastError(),
         1024, msg, len(msg), None
      ) else msg.value
   )

def getsystemdrive():
   req = c_ulong()
   nts = NtQuerySystemInformation(99, None, None, byref(req))
   if STATUS_BUFFER_TO_SMALL != nts:
      getlasterror(nts)
      return
   buf = create_unicode_buffer(req.value)
   nts = NtQuerySystemInformation(99, buf, len(buf), None)
   if 0 != nts:
      getlasterror(nts)
      return
   print(c_wchar_p(unpack_from('HHP', buf)[2]).value)

if __name__ == '__main__':
   getsystemdrive()
