__all__ = (
  'byref',
  'NTSTATUS',
  'PROCESS_QUERY_INFORMATION',
  'PROCESS_VM_READ',
  'ProcessBasicInformation',
  'CloseHandle',
  'GetCurrentProcess',
  'NtQueryInformationProcess',
  'OpenProcess',
  'ReadProcessMemory',
  'PEB',
  'PROCESS_BASIC_INFORMATION',
  'GetWin32Error',
  'GetNtError'
)
# ====================================================================================
from ctypes import (
   POINTER, Structure, Union, byref, c_byte, c_char, c_char_p, c_long, c_longlong,
   c_size_t, c_ubyte, c_ulong, c_ulonglong, c_ushort, c_void_p, c_wchar_p, sizeof,
   windll
)
# ====================================================================================
BOOL              = LONG = NTSTATUS = c_long
BOOLEAN           = c_byte
CHAR              = c_char
DWORD             = ULONG = c_ulong
GDI_HANDLE_BUFFER = 60 if 8 == sizeof(c_void_p) else 34
HANDLE            = HLOCAL = LPCVOID = LPVOID = PVOID = va_list = c_void_p
LONGLONG          = c_longlong
PSTR              = c_char_p
PWSTR             = c_wchar_p
SIZE_T            = c_size_t
UCHAR             = c_ubyte
ULONGLONG         = c_ulonglong
ULONG_PTR         = c_ulonglong if 8 == sizeof(c_void_p) else c_ulong
USHORT            = c_ushort
# ====================================================================================
PSIZE_T           = POINTER(SIZE_T)
PULONG            = POINTER(ULONG)
# ====================================================================================
FORMAT_MESSAGE_ALLOCATE_BUFFER = DWORD(0x00000100).value
FORMAT_MESSAGE_FROM_SYSTEM     = DWORD(0x00001000).value
LANG_NEUTRAL                   = DWORD(0x00000000).value
SUBLANG_DEFAULT                = DWORD(0x00000001).value
PROCESS_QUERY_INFORMATION      = DWORD(0x00000400).value
PROCESS_VM_READ                = DWORD(0x00000010).value
ProcessBasicInformation        = ULONG(0x00000000).value
# ====================================================================================
CloseHandle          = windll.kernel32.CloseHandle
CloseHandle.restype  = BOOL
CloseHandle.argtypes = [HANDLE]

FormatMessage          = windll.kernel32.FormatMessageW
FormatMessage.restype  = DWORD
FormatMessage.argtypes = [DWORD, LPCVOID, DWORD, DWORD, HLOCAL, DWORD, va_list]

GetCurrentProcess          = windll.kernel32.GetCurrentProcess
GetCurrentProcess.restype  = HANDLE
GetCurrentProcess.argtypes = []

GetLastError          = windll.kernel32.GetLastError
GetLastError.restype  = DWORD
GetLastError.argtypes = []

LocalFree          = windll.kernel32.LocalFree
LocalFree.restype  = HLOCAL
LocalFree.argtypes = [HLOCAL]

NtQueryInformationProcess          = windll.ntdll.NtQueryInformationProcess
NtQueryInformationProcess.restype  = NTSTATUS
NtQueryInformationProcess.argtypes = [HANDLE, ULONG, PVOID, ULONG, PULONG]

OpenProcess          = windll.kernel32.OpenProcess
OpenProcess.restype  = HANDLE
OpenProcess.argtypes = [DWORD, BOOL, DWORD]

ReadProcessMemory          = windll.kernel32.ReadProcessMemory
ReadProcessMemory.restype  = BOOL
ReadProcessMemory.argtypes = [HANDLE, LPCVOID, LPVOID, SIZE_T, PSIZE_T]

RtlNtStatusToDosError          = windll.ntdll.RtlNtStatusToDosError
RtlNtStatusToDosError.restype  = ULONG
RtlNtStatusToDosError.argtypes = [NTSTATUS]
# ====================================================================================
class CStruct(Structure):
   @property
   def size(self):
      return sizeof(self)
# ====================================================================================
class BIT_FIELD(Structure):
   _fields_ = (
      ('ImageUsesLargePages',          BOOLEAN, 1),
      ('IsProtectedProcess',           BOOLEAN, 1),
      ('IsImageDynamicallyRelocated',  BOOLEAN, 1),
      ('SkipPatchingUser32Forwarders', BOOLEAN, 1),
      ('IsPackagedProcess',            BOOLEAN, 1),
      ('IsAppContainer',               BOOLEAN, 1),
      ('IsProtectedProcessLight',      BOOLEAN, 1),
      ('IsLongPathAwareProcess',       BOOLEAN, 1),
   )

class BIT_FIELD_UNION(Union):
   _fields_ = (
      ('BitField', BOOLEAN),
      ('Data',     BIT_FIELD),
   )

class LIST_ENTRY(CStruct):
   _fields_ = (
      ('Flink', PVOID), # POINTER(LIST_ENTRY)
      ('Blink', PVOID), # POINTER(LIST_ENTRY)
   )

class PEB_LDR_DATA(CStruct):
   _fields_ = (
      ('Length',                          ULONG),
      ('Initialized',                     BOOLEAN),
      ('SsHandle',                        HANDLE),
      ('InLoadOrderModuleList',           LIST_ENTRY),
      ('InMemoryOrderModuleList',         LIST_ENTRY),
      ('InInitializationOrderModuleList', LIST_ENTRY),
      ('EntryInProgress',                 PVOID),
      ('ShutdownInProgress',              BOOLEAN),
      ('ShutdownThreadId',                HANDLE),
   )

class STRING(Structure):
   _fields_ = (
      ('Length',        USHORT),
      ('MaximumLength', USHORT),
      ('Buffer',        PSTR),
   )

class UNICODE_STRING(Structure):
   _fields_ = (
      ('Length',        USHORT),
      ('MaximumLength', USHORT),
      ('Buffer',        PWSTR),
   )

class CURDIR(Structure):
   _fields_ = (
      ('DosPath', UNICODE_STRING),
      ('Handle',  HANDLE),
   )

class RTL_DRIVE_LETTER_CURDIR(CStruct):
   _fields_ = (
      ('Flags',     USHORT),
      ('Length',    USHORT),
      ('TimeStamp', ULONG),
      ('DosPath',   STRING),
   )

class RTL_USER_PROCESS_PARAMETERS(CStruct):
   _fields_ = (
      ('MaximumLength',                    ULONG),
      ('Length',                           ULONG),
      ('Flags',                            ULONG),
      ('DebugFlags',                       ULONG),
      ('ConsoleHandle',                    HANDLE),
      ('ConsoleFlags',                     ULONG),
      ('StandardInput',                    HANDLE),
      ('StandardOutput',                   HANDLE),
      ('StandardError',                    HANDLE),
      ('CurrentDirectory',                 CURDIR),
      ('DllPath',                          UNICODE_STRING),
      ('ImagePathName',                    UNICODE_STRING),
      ('CommandLine',                      UNICODE_STRING),
      ('Environment',                      PVOID),
      ('StartingX',                        ULONG),
      ('StartingY',                        ULONG),
      ('CountX',                           ULONG),
      ('CountY',                           ULONG),
      ('CountCharsX',                      ULONG),
      ('CountCharsY',                      ULONG),
      ('FillAttribute',                    ULONG),
      ('WindowFlags',                      ULONG),
      ('ShowWindowFlags',                  ULONG),
      ('WindowTitle',                      UNICODE_STRING),
      ('DesktopInfo',                      UNICODE_STRING),
      ('ShellInfo',                        UNICODE_STRING),
      ('RuntimeData',                      UNICODE_STRING),
      ('CurrentDirectores',                RTL_DRIVE_LETTER_CURDIR * 32),
      ('EnvironmentSize',                  SIZE_T),
      ('EnvironmentVersion',               ULONG_PTR),
      ('PackageDependencyData',            PVOID),
      ('ProcessGroupId',                   ULONG),
      ('LoaderThreads',                    ULONG),
      ('RedirectionDllName',               UNICODE_STRING),
      ('HeapPartitionName',                UNICODE_STRING),
      ('DefaultThreadpoolCpuSetMasks',     POINTER(ULONGLONG)),
      ('DefaultThreadpoolCpuSetMaskCount', ULONG),
   )

class RTL_CRITICAL_SECTION_DEBUG(CStruct):
   _fields_ = (
      ('Type',                      USHORT),
      ('CreatorBackTraceIndex',     USHORT),
      ('CriticalSection',           PVOID), # PRTL_CRITICAL_SECTION
      ('ProcessLocksList',          LIST_ENTRY),
      ('EntryCount',                ULONG),
      ('ContentionCount',           ULONG),
      ('Flags',                     ULONG),
      ('CreatorBackTraceIndexHigh', USHORT),
      ('SpareUSHORT',               USHORT),
   )

class RTL_CRITICAL_SECTION(CStruct):
   _fields_ = (
      ('DebugInfo',      POINTER(RTL_CRITICAL_SECTION_DEBUG)),
      ('LockCount',      LONG),
      ('RecursionCount', LONG),
      ('OwningThread',   HANDLE),
      ('LockSemaphore',  HANDLE),
      ('SpinCount',      ULONG_PTR),
   )

class CROSS_PROCESS_FLAGS(CStruct):
   _fields_ = (
      ('ProcessInJob',               ULONG, 1),
      ('ProcessInitializing',        ULONG, 1),
      ('ProcessUsingVEH',            ULONG, 1),
      ('ProcessUsingVCH',            ULONG, 1),
      ('ProcessUsingFTH',            ULONG, 1),
      ('ProcessPreviouslyThrottled', ULONG, 1),
      ('ProcessCurrentlyThrottled',  ULONG, 1),
      ('ProcessImagesHotPatched',    ULONG, 1),
      ('ReservedBits0',              ULONG, 24),
   )

class CROSS_PROCESS_FLAGS_UNION(Union):
   _fields_ = (
      ('CrossProcessFlags', ULONG),
      ('Data',              CROSS_PROCESS_FLAGS),
   )

class CALLBACK_AND_SHARED_INFO(Union):
   _fields_ = (
      ('KernelCallbackTable', PVOID),
      ('UserSharedInfoPtr',   PVOID),
   )

class LARGE_INTEGER_UNION(Structure):
   _fields_ = (
      ('LowPart',  ULONG),
      ('HighPart', LONG),
   )

class LARGE_INTEGER(Union):
   _fields_ = (
      ('u1',       LARGE_INTEGER_UNION),
      ('u2',       LARGE_INTEGER_UNION),
      ('HighPart', LONGLONG),
   )

class ULARGE_INTEGER_UNION(Structure):
   _fields_ = (
      ('LowPart',  ULONG),
      ('HighPart', ULONG),
   )

class ULARGE_INTEGER(Union):
   _fields_ = (
      ('u1',       ULARGE_INTEGER_UNION),
      ('u2',       ULARGE_INTEGER_UNION),
      ('QuadPart', ULONGLONG),
   )

class TRACING_FLAGS(Structure):
   _fields_ = (
      ('HeapTracingEnabled',      ULONG, 1),
      ('CritSecTracingEnabled',   ULONG, 1),
      ('LibLoaderTracingEnabled', ULONG, 1),
      ('SpareTracingBits',        ULONG, 29),
   )

class TRACING_FLAGS_UNION(Union):
   _fields_ = (
      ('TracingFlags', ULONG),
      ('Data',         TRACING_FLAGS),
   )

class LEAP_SECOND_FALGS(Structure):
   _fields_ = (
      ('SixtySecondEnabled', ULONG, 1),
      ('Reserved',           ULONG, 31),
   )

class LEAP_SECOND_FALGS_UNION(Union):
   _fields_ = (
      ('LeapSecondFlags', ULONG),
      ('Data',            LEAP_SECOND_FALGS)
   )

class PEB(CStruct):
   _fields_ = (
      ('InheritedAddressSpace',                BOOLEAN),
      ('ReadImageFileExecOptions',             BOOLEAN),
      ('BeingDebugged',                        BOOLEAN),
      ('BitField',                             BIT_FIELD_UNION),
      ('Padding0',                             UCHAR * 4),
      ('Mutant',                               HANDLE),
      ('ImageBaseAddress',                     PVOID),
      ('Ldr',                                  POINTER(PEB_LDR_DATA)), # PPEB_LDR_DATA
      ('ProcessParameters',                    POINTER(RTL_USER_PROCESS_PARAMETERS)), # PRTL_USER_PROCESS_PARAMETERS
      ('SubSystemData',                        PVOID),
      ('ProcessHeap',                          PVOID),
      ('FastPebLock',                          POINTER(RTL_CRITICAL_SECTION)), # PRTL_CRITICAL_SECTION
      ('AtlThunkSListPtr',                     PVOID), # PSLIST_HEADER
      ('IFEOKey',                              PVOID),
      ('CrossProcessFlags',                    CROSS_PROCESS_FLAGS_UNION),
      ('Padding1',                             UCHAR * 4),
      ('CallBackAndSharedInfo',                CALLBACK_AND_SHARED_INFO),
      ('SystemReserved',                       ULONG),
      ('AtlThunkSListPtr32',                   ULONG),
      ('ApiSetMap',                            PVOID),
      ('TlsExpansionCounter',                  ULONG),
      ('Padding2',                             UCHAR * 4),
      ('TlsBitmap',                            PVOID),
      ('TlsBitmapBits',                        ULONG * 2),
      ('ReadOnlySharedMemoryBase',             PVOID),
      ('SharedData',                           PVOID),
      ('ReadOnlyStaticServerData',             POINTER(PVOID)),
      ('AnsiCodePageData',                     PVOID),
      ('OemCodePageData',                      PVOID),
      ('UnicodeCaseTableData',                 PVOID),
      ('NumberOfProcessors',                   ULONG),
      ('NtGlobalFlag',                         ULONG),
      ('CriticalSectionTimeout',               LARGE_INTEGER),
      ('HeapSegmentReserve',                   SIZE_T),
      ('HeapSegmentCommit',                    SIZE_T),
      ('HeapDeCommitTotalFreeThreshold',       SIZE_T),
      ('HeapDeCommitFreeBlockThreshold',       SIZE_T),
      ('NumberOfHeaps',                        ULONG),
      ('MaximumNumberOfHeaps',                 ULONG),
      ('ProcessHeaps',                         POINTER(PVOID)),
      ('GdiSharedHandleTable',                 PVOID),
      ('ProcessStarterHelper',                 PVOID),
      ('GdiDCAttributeList',                   ULONG),
      ('Padding3',                             UCHAR * 4),
      ('LoaderLock',                           POINTER(RTL_CRITICAL_SECTION)), # PRTL_CRITICAL_SECTION
      ('OSMajorVersion',                       ULONG),
      ('OSMinorVersion',                       ULONG),
      ('OSBuildNumber',                        USHORT),
      ('OSCSDVersion',                         USHORT),
      ('OSPlatformId',                         ULONG),
      ('ImageSubsystem',                       ULONG),
      ('ImageSubsystemMajorVersion',           ULONG),
      ('ImageSubsystemMinorVersion',           ULONG),
      ('Padding4',                             UCHAR * 4),
      ('ActiveProcessAffinityMask',            ULONG_PTR),
      ('GdiHandleBuffer',                      ULONG * GDI_HANDLE_BUFFER),
      ('PostProcessInitRoutine',               PVOID),
      ('TlsExpansionBitmap',                   PVOID),
      ('TlsExpansionBitmapBits',               ULONG * 32),
      ('SessionId',                            ULONG),
      ('Padding5',                             UCHAR * 4),
      ('AppCompatFlags',                       ULARGE_INTEGER),
      ('AppCompatFlagsUser',                   ULARGE_INTEGER),
      ('pShimData',                            PVOID),
      ('AppCompatInfo',                        PVOID),
      ('CSDVersion',                           UNICODE_STRING),
      ('ActivationContextData',                PVOID), # PACTIVATION_CONTEXT_DATA
      ('ProcessAssemblyStorageMap',            PVOID), # PASSEMBLY_STORAGE_MAP
      ('SystemDefaultActivationContextData',   PVOID), # PACTIVATION_CONTEXT_DATA
      ('SystemAssemblyStorageMap',             PVOID), # PASSEMBLY_STORAGE_MAP
      ('MinimumStackCommit',                   SIZE_T),
      ('SparePointers',                        PVOID * 4),
      ('SpareUlongs',                          ULONG * 5),
      ('WerRegistrationData',                  PVOID),
      ('WerShipAssertPtr',                     PVOID),
      ('pUnused',                              PVOID),
      ('pImageHeaderHash',                     PVOID),
      ('TracingFlags',                         TRACING_FLAGS_UNION),
      ('Padding6',                             UCHAR * 4),
      ('CsrServerReadOnlySharedMemoryBase',    ULONGLONG),
      ('TppWorkerpListLock',                   ULONG_PTR),
      ('TppWorkerpList',                       LIST_ENTRY),
      ('WaitOnAddressHashTable',               PVOID * 128),
      ('TelemetryCoverageHeader',              PVOID),
      ('CloudFileFlags',                       ULONG),
      ('CloudFileDiagFlags',                   ULONG),
      ('PlaceholderCompatibilityMode',         CHAR),
      ('PlaceholderCompatibilityModeReserved', CHAR * 7),
      ('LeapSecondData',                       PVOID), # PLEAP_SECOND_DATA
      ('LeapSecondFlags',                      LEAP_SECOND_FALGS_UNION),
      ('NtGlobalFlag2',                        ULONG),
   )

class PROCESS_BASIC_INFORMATION(CStruct):
   _fields_ = (
      ('ExitStatus',                   NTSTATUS),
      ('PebBaseAddress',               POINTER(PEB)),
      ('AffinityMask',                 ULONG_PTR),
      ('BasePriority',                 LONG),
      ('UniqueProcessId',              HANDLE),
      ('InheritedFromUniqueProcessId', HANDLE),
   )
# ====================================================================================
def getlasterror(fn) -> str:
   def MAKELANGID(p, s) -> DWORD:
      return DWORD((s << 10) | p)
   msg = HLOCAL()
   def wrapper(*args):
      if len(args) >= 2:
         raise TypeError(
            '{0} takes 1 positional agrument but {1} was given'.format(
               fn.__name__, # function name
               len(args)    # number of given parameters
            )
         )
      err = fn() if not len(args) else fn(args[0])
      FormatMessage(
         FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, None,
         err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), byref(msg), 0, None
      )
      err = PWSTR(msg.value).value
      LocalFree(msg)
      print(err.strip() if err else 'Unknown error has been occured.')
   return wrapper

@getlasterror
def GetWin32Error() -> DWORD:
   return GetLastError()

@getlasterror
def GetNtError(nts, NTSTATUS) -> DWORD:
   return RtlNtStatusToDosError(nts)
