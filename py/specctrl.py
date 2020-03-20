from ctypes import (
   POINTER, Structure, byref, c_long, c_ulong, c_void_p, c_wchar_p, sizeof, windll
)
from sys    import exit

NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
NtQuerySystemInformation.restype  = c_long
NtQuerySystemInformation.argtypes = [c_ulong, c_void_p, c_ulong, POINTER(c_ulong)]

RtlNtStatusToDosError = windll.ntdll.RtlNtStatusToDosError
RtlNtStatusToDosError.restype  = c_ulong
RtlNtStatusToDosError.argtypes = [c_long]

FormatMessage = windll.kernel32.FormatMessageW
FormatMessage.restype  = c_ulong
FormatMessage.argtypes = [c_ulong, c_void_p, c_ulong, c_ulong, c_void_p, c_ulong, c_void_p]

LocalFree = windll.kernel32.LocalFree
LocalFree.restype  = c_void_p
LocalFree.argtypes = [c_void_p]

class CStruct(Structure):
   @property
   def size(self):
      return sizeof(self)

class SpeculationControlFlags(Structure):
   _fields_ = (
      ('BpbEnabled',                               c_ulong, 1),
      ('BpbDisabledSystemPolicy',                  c_ulong, 1),
      ('BpbDisabledNoHardwareSupport',             c_ulong, 1),
      ('SpecCtrlEnumerated',                       c_ulong, 1),
      ('SpecCmdEnumerated',                        c_ulong, 1),
      ('IbrsPresent',                              c_ulong, 1),
      ('StibpPresent',                             c_ulong, 1),
      ('SmepPresent',                              c_ulong, 1),
      ('SpeculativeStoreBypassDisableAvailable',   c_ulong, 1),
      ('SpeculativeStoreBypassDisableSupported',   c_ulong, 1),
      ('SpeculativeStoreBypassDisabledSystemWide', c_ulong, 1),
      ('SpeculativeStoreBypassDisabledKernel',     c_ulong, 1),
      ('SpeculativeStoreBypassDisableRequired',    c_ulong, 1),
      ('BpbDisabledKernelToUser',                  c_ulong, 1),
      ('SpecCtrlRetpolineEnabled',                 c_ulong, 1),
      ('SpecCtrlImportOptimizationEnabled',        c_ulong, 1),
      ('EnhancedIbrs',                             c_ulong, 1),
      ('HvL1tfStatusAvailable',                    c_ulong, 1),
      ('HvL1tfProcessorNotAffected',               c_ulong, 1),
      ('HvL1tfMigitationEnabled',                  c_ulong, 1),
      ('HvL1tfMigitationNotEnabled_Hardware',      c_ulong, 1),
      ('HvL1tfMigitationNotEnabled_LoadOption',    c_ulong, 1),
      ('HvL1tfMigitationNotEnabled_CoreScheduler', c_ulong, 1),
      ('EnhancedIbrsReported',                     c_ulong, 1),
      ('MdsHardwareProtected',                     c_ulong, 1),
      ('MbClearEnabled',                           c_ulong, 1),
      ('MbClearReported',                          c_ulong, 1),
      ('TsxCtrlStatus',                            c_ulong, 2),
      ('TsxCtrlReported',                          c_ulong, 1),
      ('TaaHardwareImmune',                        c_ulong, 1),
      ('Reserved',                                 c_ulong, 1),
   )

class SYSTEM_SPECULATION_CONTROL_INFORMATION(CStruct):
   _fields_ = ('SpeculationControlFlags', SpeculationControlFlags),

if __name__ == '__main__':
   ssci = SYSTEM_SPECULATION_CONTROL_INFORMATION()
   if 0 != (nts := NtQuerySystemInformation(c_ulong(201), byref(ssci), ssci.size, None)):
       msg, err = c_wchar_p(), RtlNtStatusToDosError(nts)
       if 0 != FormatMessage(0x1100, None, err, 0x400, byref(msg), 0, None):
          print(msg.value.strip() if msg.value else 'Unknown error has been occured.')
          if LocalFree(msg):
             print('LocalFree fatal error.')
       exit(err)
   [print(
      '{0:41}: {1}'.format(n, getattr(ssci.SpeculationControlFlags, n))
   ) for n, t, _ in ssci.SpeculationControlFlags._fields_]
