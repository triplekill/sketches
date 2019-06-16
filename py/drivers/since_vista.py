# -*- coding: utf-8 -*-
from ctypes import (
   POINTER, Structure, byref, cast, create_unicode_buffer, c_char_p,
   c_ubyte, c_ulong, c_ushort, c_void_p, sizeof, windll
)

class RTL_MODULE_BASIC_INFO(Structure):
   _fields_ = [
      ('ImageBase', c_void_p),
   ]

class RTL_MODULE_EXTENDED_INFO(Structure):
   _fields_ = [
      ('BasicInfo',      RTL_MODULE_BASIC_INFO),
      ('ImageSize',      c_ulong),
      ('FileNameOffset', c_ushort),
      ('FullPathName',   c_ubyte * 0x100),
   ]
   @property
   def ImageName(self):
     return str(cast(
        self.FullPathName, c_char_p).value, 'utf-8'
     ).split('\\')[-1]

FormatMessage             = windll.kernel32.FormatMessageW
RtlNtStatusToDosError     = windll.ntdll.RtlNtStatusToDosError
"""
NTSYSAPI
NTSTATUS
NTAPI
RtlQueryModuleInformation(
   _In_out_ PULONG ModuleInformationLength,
   _In_     ULONG  SizePerModule,
   _Out_write_bytes_opt_(ModuleInformationLength) PVOID ModuleInformation
);
"""
RtlQueryModuleInformation = windll.ntdll.RtlQueryModuleInformation
RtlQueryModuleInformation.restype = c_ulong

def getlasterror(ntstatus):
   msg = create_unicode_buffer(0x100)
   print(msg.value if FormatMessage(
      0x12FF, None, RtlNtStatusToDosError(ntstatus),
      1024, msg, len(msg), None
   ) else 'Unknown error has been occured.')

def getmoduleslist():
   # KUSER_SHARED_DATA -> NtMajorVersion
   if 6 > c_ulong.from_address(0x7FFE026C).value:
      print('Sorry but this requires Vista or higher.')
      return
   req, sz = c_ulong(), sizeof(RTL_MODULE_EXTENDED_INFO)
   nts = RtlQueryModuleInformation(byref(req), sz, None)
   if 0 != nts:
      getlasterror(nts)
      return
   buf = create_unicode_buffer(req.value)
   nts = RtlQueryModuleInformation(byref(req), sz, buf)
   if 0 != nts:
      getlasterror(nts)
      return
   return cast(
      buf, POINTER(RTL_MODULE_EXTENDED_INFO * (req.value // sz))
   ).contents

if __name__ == '__main__':
   modules = getmoduleslist()
   if modules:
      fmt = ['%s %8s %27s', '%s %16s %27s'][sizeof(c_void_p) // 4 - 1]
      print(fmt % ('Base', 'Size', 'Driver Name'))
      print(fmt % ('-' * 4, '-' * 4, '-' * 11))
      for i in modules:
         print('%x %-7x (%7d kb) %s' % (
            i.BasicInfo.ImageBase, i.ImageSize, i.ImageSize / 1024, i.ImageName
         ))
