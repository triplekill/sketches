# -*- coding: utf-8 -*-
from ctypes import (
   Structure, byref, create_unicode_buffer, c_ubyte, c_ulong,
   c_ulonglong, c_ushort, sizeof, windll
)
from enum   import IntEnum

class GUID(Structure):
   _fields_ = [
      ('Data1', c_ulong),
      ('Data2', c_ushort),
      ('Data3', c_ushort),
      ('Data4', c_ubyte * 8),
   ]
   def to_str(self):
      d4h = ''.join(['{:02X}'.format(x) for x in self.Data4])
      return '{{{0:X}-{1:X}-{2:X}-{3}-{4}}}'.format(
         self.Data1, self.Data2, self.Data3, d4h[:4], d4h[4:]
      )

FIRMWARETYPE = IntEnum('FIRMWARETYPE', 'Unknown BIOS UEFI Max')

class SYSTEM_BOOT_ENVIRONMENT_INFORMATION(Structure):
   _fields_ = [
      ('BootIdentifier', GUID),
      ('_FirmwareType',  c_ulonglong),
      ('BootFlags',      c_ulonglong),
   ]
   @property
   def FirmwareType(self):
      return FIRMWARETYPE(
         self._FirmwareType + 1
      ).name if self._FirmwareType else None

def getlasterror(nts):
   msg = create_unicode_buffer(0x100)
   print('Unknown error has been occured.'
      if not windll.kernel32.FormatMessageW(
         0x12FF, None,
         windll.ntdll.RtlNtStatusToDosError(nts),
         1024, msg, len(msg), None
      ) else msg.value
   )

def getbootenvironment():
   sbei = SYSTEM_BOOT_ENVIRONMENT_INFORMATION()
   nts = windll.ntdll.NtQuerySystemInformation(
      90, byref(sbei), sizeof(sbei), None
   )
   if 0 != nts:
      getlasterror(nts)
      return
   print('Boot identifier: %s\nFirmware type  : %s' % (
      sbei.BootIdentifier.to_str(), sbei.FirmwareType
   ))

if __name__ == '__main__':
   getbootenvironment()
