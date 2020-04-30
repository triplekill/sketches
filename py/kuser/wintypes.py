__all__ = 'KUSER_SHARED_DATA'
#================================================================================================
from ctypes   import (
   Structure, Union, c_byte, c_long, c_longlong, c_ubyte, c_ulong, c_ulonglong, c_ushort, c_wchar
)
from datetime import datetime, timedelta
from enum     import IntEnum
# ===============================================================================================
BOOLEAN   = c_byte
LONG      = c_long
LONGLONG  = c_longlong
UCHAR     = c_ubyte
ULONG     = c_ulong
ULONGLONG = c_ulonglong
USHORT    = c_ushort
WCHAR     = c_wchar
# ===============================================================================================
MAX_PATH  = 260
MAXIMUM_STATE_FEATURES = PROCESSOR_FEATURE_MAX = 64
# ===============================================================================================
class KSYSTEM_TIME(Structure):
   _fields_ = (
      ('LowPart',   ULONG),
      ('High1Time', LONG),
      ('High2Time', LONG),
   )

NT_PRODUCT_TYPE = IntEnum('NT_PRODUCT_TYPE', (
   'NtProductWinNt',
   'NtProductLanManNt',
   'NtProductServer',
), start=1)

ALTERNATIVE_ARCHITECTURE_TYPE = IntEnum('ALTERNATIVE_ARCHITECTURE_TYPE', (
   'StandardDesign',
   'NEC98x86',
   'EndAlternatives',
), start=0)

class LARGE_INTEGER_UNION(Structure):
   _fields_ = (
      ('LowPart',  ULONG),
      ('HighPart', LONG),
   )

class LARGE_INTEGER(Union):
   _fields_ = (
      ('u1',       LARGE_INTEGER_UNION),
      ('u2',       LARGE_INTEGER_UNION),
      ('QuadPart', LONGLONG),
   )

class DUMMYSTRUCTNAME1(Structure):
   _fields_ = (
      ('NXSupportPolicy',             UCHAR, 2),
      ('SEHValidationPolicy',         UCHAR, 2),
      ('CurDirDevicesSkippedForDlls', UCHAR, 2),
      ('Reserved',                    UCHAR, 2),
   )

class DUMMYUNIONNAME1(Union):
   _fields_ = (
      ('MitigationPolicies', UCHAR),
      ('Data',               DUMMYSTRUCTNAME1),
   )

class DUMMYSTRUCTNAME2(Structure):
   _fields_ = (
      ('DbgErrorPortPresent',       ULONG, 1),
      ('DbgElevationEnabled',       ULONG, 1),
      ('DbgVirtEnabled',            ULONG, 1),
      ('DbgInstallerDetectEnabled', ULONG, 1),
      ('DbgLkgEnabled',             ULONG, 1),
      ('DbgDynProcessorEnabled',    ULONG, 1),
      ('DbgConsoleBrokerEnabled',   ULONG, 1),
      ('DbgSecureBootEnabled',      ULONG, 1),
      ('DbgMultiSessionSku',        ULONG, 1),
      ('DbgMultiUsersInSessionSku', ULONG, 1),
      ('DbgStateSeparationEnabled', ULONG, 1),
      ('SpareBits',                 ULONG, 21),
   )

class DUMMYUNIONNAME2(Union):
   _fields_ = (
      ('SharedDataFlags', ULONG),
      ('Data',            DUMMYSTRUCTNAME2),
   )

class DUMMYSTRUCTNAME3(Structure):
   _fields_ = (
      ('ReservedTickCountOverlay', ULONG * 3),
      ('TickCountPad',             ULONG * 1),
   )

class DUMMYUNIONNAME3(Union):
   _fields_ = (
      ('TickCount',      KSYSTEM_TIME),
      ('_TickCountQuad', ULONGLONG),
      ('Data',           DUMMYSTRUCTNAME3),
   )
   @property
   def TickCountQuad(self):
      return timedelta(seconds=self._TickCountQuad // 100)

class DUMMYSTRUCTNAME4(Structure):
   _fields_ = (
      ('QpcBypassEnabled', UCHAR),
      ('QpcShift',         UCHAR),
   )

class DUMMYUNIONNAME4(Union):
   _fields_ = (
      ('QpcData', USHORT),
      ('Data',    DUMMYSTRUCTNAME4),
   )

class XSTATE_FEATURE(Structure):
   _fields_ = (
      ('Offset', ULONG),
      ('Size',   ULONG),
   )

class XSTATE_FLAGS(Structure):
   _fields_ = (
      ('OptimizedSave',    ULONG, 1),
      ('CompactionEnaled', ULONG, 1), # BOOL
   )

class XSTATE_FLAGS_UNION(Union):
   _fields_ = (
      ('ControlFlags', ULONG),
      ('Data',         XSTATE_FLAGS),
   )

class XSTATE_CONFIGURATION(Structure):
   _fields_ = (
      ('EnabledFeatures',                      ULONGLONG),
      ('EnabledVolatileFeatures',              ULONGLONG),
      ('Size',                                 ULONG),
      ('ControlFlags',                         XSTATE_FLAGS_UNION),
      ('Features',                             XSTATE_FEATURE * MAXIMUM_STATE_FEATURES),
      ('EnabledSupervisorFeatures',            ULONGLONG),
      ('AlignedFeatures',                      ULONGLONG),
      ('AllFeatureSize',                       ULONG),
      ('AllFeatures',                          ULONG * MAXIMUM_STATE_FEATURES),
      ('EnabledUserVisibleSupervisorFeatures', ULONGLONG),
   )
# ===============================================================================================
class KUSER_SHARED_DATA(Structure):
   _fields_ = (
      ('TickCountLowDeprecated',            ULONG),
      ('TickCountMultiplier',               ULONG),
      ('InterruptTime',                     KSYSTEM_TIME),
      ('_SystemTime',                       KSYSTEM_TIME),
      ('TimeZoneBias',                      KSYSTEM_TIME),
      ('_ImageNumberLow',                   USHORT),
      ('_ImageNumberHigh',                  USHORT),
      ('NtSystemRoot',                      WCHAR * MAX_PATH),
      ('MaxStackTraceDepth',                ULONG),
      ('CryptoExponent',                    ULONG),
      ('TimeZoneId',                        ULONG),
      ('LargePageMinimum',                  ULONG),
      ('AitSamplingValue',                  ULONG),
      ('AppCompatFlag',                     ULONG),
      ('RNGSeedVersion',                    ULONGLONG),
      ('GlobalValidationRunlevel',          ULONG),
      ('TimeZoneBiasStamp',                 LONG),
      ('NtBuildNumber',                     ULONG),
      ('_NtProductType',                    ULONG), # NT_PRODUCT_TYPE
      ('_ProductTypeIsValid',               BOOLEAN),
      ('Reserved0',                         UCHAR * 1),
      ('NativeProcessorArchitecture',       USHORT),
      ('NtMajorVersion',                    ULONG),
      ('NtMinorVersion',                    ULONG),
      ('ProcessorFeatures',                 BOOLEAN * PROCESSOR_FEATURE_MAX),
      ('Reserved1',                         ULONG),
      ('Reserved3',                         ULONG),
      ('TimeSlip',                          ULONG),
      ('_AlternativeArchitecture',          ULONG), # ALTERNATIVE_ARCHITECTURE_TYPE
      ('BootId',                            ULONG),
      ('SystemExpirationDate',              LARGE_INTEGER),
      ('SuiteMask',                         ULONG),
      ('KdDebuggerEnabled',                 BOOLEAN),
      ('MitigationPolicies',                DUMMYUNIONNAME1),
      ('CyclesPerYield',                    USHORT),
      ('ActiveConsoleId',                   ULONG),
      ('DismountCount',                     ULONG),
      ('ComPlusPackage',                    ULONG),
      ('LastSystemRITEventTickCount',       ULONG),
      ('NumberOfPhysicalPages',             ULONG),
      ('SafeBootMode',                      BOOLEAN),
      ('VirtualizationFlags',               UCHAR),
      ('Reserved12',                        UCHAR * 2),
      ('SharedDataFlags',                   DUMMYUNIONNAME2),
      ('DataFlagsPad',                      ULONG * 1),
      ('TestRetInstruction',                ULONGLONG),
      ('QpcFrequency',                      LONGLONG),
      ('SystemCall',                        ULONG),
      ('SystemCallPad0',                    ULONG),
      ('SystemCallPad',                     ULONGLONG * 2),
      ('TickCount',                         DUMMYUNIONNAME3),
      ('Cookie',                            ULONG),
      ('CookiePad',                         ULONG * 1),
      ('ConsoleSessionForegroundProcessId', LONGLONG),
      ('TimeUpdateLock',                    ULONGLONG),
      ('BaselineSystemTimeQpc',             ULONGLONG),
      ('BaselineInterruptTimeQpc',          ULONGLONG),
      ('QpcSystemTimeIncrement',            ULONGLONG),
      ('QpcInterruptTimeIncrement',         ULONGLONG),
      ('QpcSystemTimeIncrementShift',       UCHAR),
      ('QpcInterruptTimeIncrementShift',    UCHAR),
      ('UnparkedProcessorCount',            USHORT),
      ('EnclaveFeatureMask',                ULONG * 4),
      ('TelemetryCoverageRound',            ULONG),
      ('UserModeGlobalLogger',              USHORT * 16),
      ('ImageFileExecutionOptions',         ULONG),
      ('LangGenerationCount',               ULONG),
      ('Reserved4',                         ULONGLONG),
      ('InterruptTimeBias',                 ULONGLONG),
      ('QpcBias',                           ULONGLONG),
      ('ActiveProcessorCount',              ULONG),
      ('ActiveGroupCount',                  UCHAR),
      ('Reserved9',                         UCHAR),
      ('QpcData',                           DUMMYUNIONNAME4),
      ('TimeZoneBiasEffectiveStart',        LARGE_INTEGER),
      ('TimeZoneBiasEffectiveEnd',          LARGE_INTEGER),
      ('XState',                            XSTATE_CONFIGURATION),
   )
   @property
   def ImageNumberLow(self):
      if 0x14C == self._ImageNumberLow:
         return 'IMAGE_FILE_MACHINE_I386'
      if 0x8664 == self._ImageNumberLow:
         return 'IMAGE_FILE_MACHINE_AMD64'
      return 'Unknown'
   @property
   def ImageNumberHigh(self):
      if 0x14C == self._ImageNumberHigh:
         return 'IMAGE_FILE_MACHINE_I386'
      if 0x8664 == self._ImageNumberHigh:
         return 'IMAGE_FILE_MACHINE_AMD64'
      return 'Unknown'
   @property
   def SystemTime(self):
      return (datetime(1970, 1, 1) + timedelta(
         microseconds=(
            (self._SystemTime.High1Time << 32 | self._SystemTime.LowPart) - 116444736 * 1e9
         ) // 10
      )).strftime('%m/%d/%Y %H:%M:%S')
   @property
   def NtProductType(self):
      return NT_PRODUCT_TYPE(
         self._NtProductType
      ).name if self._NtProductType else None
   @property
   def ProductTypeIsValid(self):
      return 'valid' if self._ProductTypeIsValid else 'invalid'
   @property
   def AlternativeArchitecture(self):
      return ALTERNATIVE_ARCHITECTURE_TYPE(
         self._AlternativeArchitecture
      ).name if 0 <= self._AlternativeArchitecture else None
