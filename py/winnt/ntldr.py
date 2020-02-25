import wintypes as nt
# ====================================================================================
class RTL_PROCESS_MODULE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 284, x64 = 296
      ('Section',          nt.HANDLE),
      ('MappedBase',       nt.PVOID),
      ('ImageBase',        nt.PVOID),
      ('ImageSize',        nt.ULONG),
      ('Flags',            nt.ULONG),
      ('LoadOrderIndex',   nt.USHORT),
      ('InitOrderIndex',   nt.USHORT),
      ('LoadCount',        nt.USHORT),
      ('OffsetToFileName', nt.USHORT),
      ('FullPathName',     nt.UCHAR * 256),
   )

class RTL_PROCESS_MODULES(nt.CStruct):
   _fields_ = ( # x86 = 288, x64 = 304
      ('NumberOfModules', nt.ULONG),
      ('Modules',         RTL_PROCESS_MODULE_INFORMATION * 1)
   )
