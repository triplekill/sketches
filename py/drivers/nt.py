# -*- coding: utf-8 -*-
from ctypes import (
   POINTER, Structure, byref, cast, create_unicode_buffer, c_char,
   c_ulong, c_ushort, c_void_p, sizeof, windll
)

class RTL_PROCESS_MODULE_INFORMATION(Structure):
   _fields_ = [
      ('Section',          c_void_p),
      ('MappedBase',       c_void_p),
      ('ImageBase',        c_void_p),
      ('ImageSize',        c_ulong),
      ('Flags',            c_ulong),
      ('LoadOrderIndex',   c_ushort),
      ('InitOrderIndex',   c_ushort),
      ('LoadCount',        c_ushort),
      ('OffsetToFileName', c_ushort),
      ('FullPathName',     c_char * 0x100),
   ]
   @property
   def ImageName(self):
      return str(self.FullPathName.split(b'\\')[-1], 'utf-8')

class RTL_PROCESS_MODULES(Structure):
   _fields_ = [
      ('NumberOfModules', c_ulong),
      ('Modules', RTL_PROCESS_MODULE_INFORMATION * 1),
   ]
   def to_array(self):
      return cast(self.Modules, POINTER(
         RTL_PROCESS_MODULE_INFORMATION * self.NumberOfModules
      )).contents

FormatMessage            = windll.kernel32.FormatMessageW
NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
RtlNtStatusToDosError    = windll.ntdll.RtlNtStatusToDosError

NtQuerySystemInformation.restype = c_ulong

def getlasterror(ntstatus):
   msg = create_unicode_buffer(0x100)
   print(msg.value if FormatMessage(
      0x12FF, None, RtlNtStatusToDosError(ntstatus),
      1024, msg, len(msg), None
   ) else 'Unknown error has been occured.')

def getbufferdata():
   req = c_ulong() # get real SystemModuleInformation buffer length
   nts = NtQuerySystemInformation(11, None, 0, byref(req))
   if 0xC0000004 != nts: # STATUS_INFO_LENGTH_MISMATCH
      getlasterror(nts)
      return
   buf = create_unicode_buffer(req.value)
   nts = NtQuerySystemInformation(11, buf, len(buf), None)
   if 0 != nts:
      getlasterror(nts)
      return
   return buf

if __name__ == '__main__':
   buf = getbufferdata()
   if buf:
      rpm = cast(buf, POINTER(RTL_PROCESS_MODULES)).contents.to_array()
      fmt = ['%s %8s %27s', '%s %16s %27s'][sizeof(c_void_p) // 4 - 1]
      print(fmt % ('Base', 'Size', 'Driver Name'))
      print(fmt % ('-' * 4, '-' * 4, '-' * 11))
      for i in rpm:
         print('%x %-7x (%7d kb) %s' % (
            i.ImageBase, i.ImageSize, i.ImageSize / 1024, i.ImageName
         ))
