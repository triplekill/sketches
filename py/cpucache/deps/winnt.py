# -*- coding: utf-8 -*-
__all__ = ['getcpucache']

from ctypes import (
   POINTER, Structure, Union, byref, cast, create_string_buffer,
   create_unicode_buffer, c_byte, c_ulong, c_ulonglong, c_ushort,
   c_void_p, sizeof, windll
)
from enum   import IntEnum

class PROCESSORCORE(Structure):
   _fields_ = [
      ('Flags', c_byte),
   ]

class NUMANODE(Structure):
   _fields_ = [
      ('NodeNumber', c_ulong),
   ]

class PROCESSOR_CACHE_TYPE(IntEnum):
   CacheUnified     = 0,
   CacheInstruction = 1,
   CacheData        = 2,
   CacheTrace       = 3

class CACHE_DESCRIPTOR(Structure):
   _fields_ = [
      ('Level',         c_byte),
      ('Associativity', c_byte),
      ('LineSize',      c_ushort),
      ('Size',          c_ulong),
      ('_Type',         c_ulong),
   ]
   @property
   def Type(self):
      return PROCESSOR_CACHE_TYPE(self._Type).name

class SYSTEM_LOGICAL_PROCESSOR_INFORMATION_UNION(Union):
   _fields_= [
      ('ProcessorCore', PROCESSORCORE),
      ('NumaNode',      NUMANODE),
      ('Cache',         CACHE_DESCRIPTOR),
      ('Reserved',      c_ulonglong * 2),
   ]

UINT_PTR = c_ulonglong if sizeof(c_void_p) == sizeof(c_ulonglong) else c_ulong

class SYSTEM_LOGICAL_PROCESSOR_INFORMATION(Structure):
   _fields_ = [
      ('ProcessorMask', UINT_PTR),
      ('Relationship',  UINT_PTR),
      ('ProcessorInfo', SYSTEM_LOGICAL_PROCESSOR_INFORMATION_UNION),
   ]

FormatMessage                  = windll.kernel32.FormatMessageW
GetLastError                   = windll.kernel32.GetLastError
GetLogicalProcessorInformation = windll.kernel32.GetLogicalProcessorInformation

def getlasterror():
   msg = create_unicode_buffer(0x100)
   return msg.value if FormatMessage(
      0x12FF, None, GetLastError(), 1024, msg, len(msg), None
   ) else 'Unknown error has been occured.'

def getcpucache():
   bsz = c_ulong() # retrieve required buffer size
   res = GetLogicalProcessorInformation(None, byref(bsz))
   if not res and GetLastError() == 0x0000007A: # ERROR_INSUFFICIENT_BUFFER
      buf = create_string_buffer(bsz.value)
      if not GetLogicalProcessorInformation(buf, byref(bsz)):
         getlasterror()
         return
   fmt = '{0.Type:<19}L{0.Level}: {1:5} KB, Assoc {0.Associativity:2}, LineSize {0.LineSize}'
   nxt = sizeof(SYSTEM_LOGICAL_PROCESSOR_INFORMATION) # CPU > 1?
   for i in range(0, bsz.value, nxt):
      slpi = cast(
         buf[i:nxt], POINTER(SYSTEM_LOGICAL_PROCESSOR_INFORMATION)
      ).contents
      if 2 == slpi.Relationship: # RelationCache
         inf = slpi.ProcessorInfo.Cache
         yield fmt.format(inf, inf.Size // 1024)
      nxt *= 2 # move to the next entry
