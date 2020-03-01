import wintypes as nt

from ctypes   import Structure, Union, windll
from enum     import IntEnum
from ntkeapi  import KTHREAD_STATE, KWAIT_REASON
# ====================================================================================
NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
NtQueryTimerResolution   = windll.ntdll.NtQueryTimerResolution
# ====================================================================================
SYSTEM_INFORMATION_CLASS = IntEnum('SYSTEM_INFORMATION_CLASS', (
   'SystemBasicInformation', # q: SYSTEM_BASIC_INFORMATION
   'SystemProcessorInformation', # q: SYSTEM_PROCESSOR_INFORMATION
   'SystemPerformanceInformation', # q: SYSTEM_PERFORMANCE_INFORMATION
   'SystemTimeOfDayInformation', # q: SYSTEM_TIMEOFDAY_INFORMATION
   'SystemPathInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemProcessInformation', # q: SYSTEM_PROCESS_INFORMATION
   'SystemCallCountInformation', # q: SYSTEM_CALL_COUNT_INFORMATION
   'SystemDeviceInformation', # q: SYSTEM_DEVICE_INFORMATION
   'SystemProcessorPerformanceInformation', # q: SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION
   'SystemFlagsInformation', # q: SYSTEM_FLAGS_INFORMATION
   'SystemCallTimeInformation', # r: STATUS_NOT_IMPLEMENTED, q: SYSTEM_CALL_TIME_INFORMATION
   'SystemModuleInformation', # q: RTL_PROCESS_MODULES (ntldr.py)
   'SystemLocksInformation', # q: RTL_PROCESS_LOCKS
   'SystemStackTraceInformation', # q: RTL_PROCESS_BACKTRACES
   'SystemPagedPoolInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemNonPagedPoolInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemHandleInformation', # q: SYSTEM_HANDLE_INFORMATION
   'SystemObjectInformation', # q: SYSTEM_OBJECTTYPE_INFORMATION (SYSTEM_OBJECT_INFORMATION)
   'SystemPageFileInformation', # q: SYSTEM_PAGEFILE_INFORMATION
   'SystemVdmInstemulInformation', # q: SYSTEM_VDM_INSTEMUL_INFO
   'SystemVdmBopInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemFileCacheInformation', # q: SYSTEM_FILECACHE_INFORMATION, s: SeIncreaseQuotaPrivilege
   'SystemPoolTagInformation', # q: SYSTEM_POOLTAG_INFORMATION
   'SystemInterruptInformation', # q: SYSTEM_INTERRUPT_INFORMATION
   'SystemDpcBehaviorInformation', # q: SYSTEM_DPC_BEHAVIOR_INFORMATION, s: SeLoadDriverPrivilege
   'SystemFullMemoryInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemLoadGdiDriverInformation', # kernel-mode
   'SystemUnloadGdiDriverInformation', # kernel-mode
   'SystemTimeAdjustmentInformation', # q: SYSTEM_QUERY_TIME_ADJUST_INFORMATION, s: SeSystemTimePrivilege
   'SystemSummaryMemoryInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemMirrorMemoryInformation', # q: value "Kernel-MemoryMirroringSupported", s: SeShutdownPrivilege
   'SystemPerformanceTraceInformation', # depends on EVENT_TRACE_INFORMATION_CLASS
   'SystemObsolete0', # r: STATUS_NOT_IMPLEMENTED
   'SystemExceptionInformation', # q: SYSTEM_EXCEPTION_INFORMATION
   'SystemCrashDumpStateInformation', # q: SYSTEM_CRASH_DUMP_STATE_INFORMATION, s: SeDebugPrivilege
   'SystemKernelDebuggerInformation', # q: SYSTEM_KERNEL_DEBUGGER_INFORMATION
   'SystemContextSwitchInformation', # q: SYSTEM_CONTEXT_SWITCH_INFORMATION
   'SystemRegistryQuotaInformation', # q: SYSTEM_REGISTRY_QUOTA_INFORMATION, s: SeIncreaseQuotaPrivilege
   'SystemExtendServiceTableInformation', # s: SeLoadDriverPrivilege (loads win32k.sys)
   'SystemPrioritySeperation', # s: SeTcbPrivilege
   'SystemVerifierAddDriverInformation', # s: SeDebugPrivilege
   'SystemVerifierRemoveDriverInformation', # s: SeDebugPrivilege
   'SystemProcessorIdleInformation', # q: SYSTEM_PROCESSOR_IDLE_INFORMATION
   'SystemLegacyDriverInformation', # q: SYSTEM_LEGACY_DRIVER_INFORMATION
   'SystemCurrentTimeZoneInformation', # q: RTL_TIME_ZONE_INFORMATION
   'SystemLookasideInformation', # q: SYSTEM_LOOKASIDE_INFORMATION
   'SystemTimeSlipNotification', # s: SeSystemPrivilege
   'SystemSessionCreate', # r: STATUS_NOT_IMPLEMENTED
   'SystemSessionDetach', # r: STATUS_NOT_IMPLEMENTED
   'SystemSessionInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemRangeStartInformation', # q: SYSTEM_RANGE_START_INFORMATION
   'SystemVerifierInformation', # q: SYSTEM_VERIFIER_INFORMATION, s: SeDebugPrivilege
   'SystemVerifierThunkExtend', # kernel-mode
   'SystemSessionProcessInformation', # q: SYSTEM_SESSION_PROCESS_INFORMATION
   'SystemLoadGdiDriverInSystemSpace', # kernel-mode (same as SystemLoadGdiDriverInformation)
   'SystemNumaProcessorMap', # q: SYSTEM_NUMA_INFORMATION
   'SystemPrefetcherInformation', # q: PREFETCHER_INFORMATION
   'SystemExtendedProcessInformation', # q: SYSTEM_PROCESS_INFORMATION
   'SystemRecommendedSharedDataAlignment', # q: ?
   'SystemComPlusPackage', # q: ?
   'SystemNumaAvailableMemory', # q: SYSTEM_NUMA_INFORMATION
   'SystemProcessorPowerInformation', # q: SYSTEM_PROCESSOR_POWER_INFORMATION
   'SystemEmulationBasicInformation', # q: SYSTEM_BASIC_INFORMATION ?
   'SystemEmulationProcessorInformation', # q: SYSTEM_PROCESSOR_INFORMATION ?
   'SystemExtendedHandleInformation', # q: SYSTEM_HANDLE_INFORMATION_EX
   'SystemLostDelayedWriteInformation', # q: ULONG
   'SystemBigPoolInformation', # q: SYSTEM_BIGPOOL_INFORMATION
   'SystemSessionPoolTagInformation', # q: SYSTEM_SESSION_POOLTAG_INFORMATION
   'SystemSessionMappedViewInformation', # q: SYSTEM_SESSION_MAPPED_VIEW_INFORMATION
   'SystemHotpatchInformation', # q: SYSTEM_HOTPATCH_CODE_INFORMATION
   'SystemObjectSecurityMode', # q: ULONG
   'SystemWatchdogTimerHandler', # kernel-mode
   'SystemWatchdogTimerInformation', # kernel-mode, q: SYSTEM_WATCHDOG_TIMER_INFORMATION
   'SystemLogicalProcessorInformation', # SYSTEM_LOGICAL_PROCESSOR_INFORMATION
   'SystemWow64SharedInformationObsolete', # r: STATUS_NOT_IMPLEMENTED
   'SystemRegisterFirmwareTableInformationHandler', # kernel-mode
   'SystemFirmwareTableInformation', # q: SYSTEM_FIRMWARE_TABLE_INFORMATION
   'SystemModuleInformationEx', # q: RTL_PROCESS_MODULE_INFORMATION_EX
   'SystemVerifierTriageInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemSuperfetchInformation', # q: SUPERFETCH_INFORMATION
   'SystemMemoryListInformation',
   'SystemFileCacheInformationEx',
   'SystemThreadPriorityClientIdInformation',
   'SystemProcessorIdleCycleTimeInformation',
   'SystemVerifierCancellationInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemProcessorPowerInformationEx', # r: STATUS_NOT_IMPLEMENTED
   'SystemRefTraceInformation',
   'SystemSpecialPoolInformation',
   'SystemProcessIdInformation',
   'SystemErrorPortInformation',
   'SystemBootEnvironmentInformation',
   'SystemHypervisorInformation',
   'SystemVerifierInformationEx',
   'SystemTimeZoneInformation',
   'SystemImageFileExecutionOptionsInformation',
   'SystemCoverageInformation',
   'SystemPrefetchPatchInformation', # r: STATUS_NOT_IMPLEMENTED
   'SystemVerifierFaultsInformation',
   'SystemSystemPartitionInformation',
   'SystemSystemDiskInformation',
   'SystemProcessorPerformanceDistribution',
   'SystemNumaProximityNodeInformation',
   'SystemDynamicTimeZoneInformation',
   'SystemCodeIntegrityInformation',
   'SystemProcessorMicrocodeUpdateInformation',
   'SystemProcessorBrandString',
   'SystemVirtualAddressInformation',
   'SystemLogicalProcessorAndGroupInformation',
   'SystemProcessorCycleTimeInformation',
   'SystemStoreInformation',
   'SystemRegistryAppendString',
   'SystemAitSamplingValue',
   'SystemVhdBootInformation',
   'SystemCpuQuotaInformation',
   'SystemNativeBasicInformation', # r: STATUS_NOT_IMPLEMENTED, q: SYSTEM_BASIC_INFORMATION ?
   'SystemErrorPortTimeouts', # r: STATUS_NOT_IMPLEMENTED
   'SystemLowPriorityIoInformation',
   'SystemBootEntropyInformation',
   'SystemVerifierCountersInformation',
   'SystemPagedPoolInformationEx',
   'SystemSystemPtesInformationEx',
   'SystemNodeDistanceInformation',
   'SystemAcpiAuditInformation',
   'SystemBasicPerformanceInformation',
   'SystemQueryPerformanceCounterInformation',
   'SystemSessionBigPoolInformation',
   'SystemBootGraphicsInformation',
   'SystemScrubPhysicalMemoryInformation',
   'SystemBadPageInformation',
   'SystemProcessorProfileControlArea',
   'SystemCombinePhysicalMemoryInformation',
   'SystemEntropyInterruptTimingInformation',
   'SystemConsoleInformation',
   'SystemPlatformBinaryInformation',
   'SystemPolicyInformation',
   'SystemHypervisorProcessorCountInformation',
   'SystemDeviceDataInformation',
   'SystemDeviceDataEnumerationInformation',
   'SystemMemoryTopologyInformation',
   'SystemMemoryChannelInformation',
   'SystemBootLogoInformation',
   'SystemProcessorPerformanceInformationEx',
   'SystemCriticalProcessErrorLogInformation',
   'SystemSecureBootPolicyInformation',
   'SystemPageFileInformationEx',
   'SystemSecureBootInformation',
   'SystemEntropyInterruptTimingRawInformation',
   'SystemPortableWorkspaceEfiLauncherInformation',
   'SystemFullProcessInformation',
   'SystemKernelDebuggerInformationEx',
   'SystemBootMetadataInformation',
   'SystemSoftRebootInformation',
   'SystemElamCertificateInformation',
   'SystemOfflineDumpConfigInformation',
   'SystemProcessorFeaturesInformation',
   'SystemRegistryReconciliationInformation',
   'SystemEdidInformation',
   'SystemManufacturingInformation',
   'SystemEnergyEstimationConfigInformation',
   'SystemHypervisorDetailInformation',
   'SystemProcessorCycleStatsInformation',
   'SystemVmGenerationCountInformation',
   'SystemTrustedPlatformModuleInformation',
   'SystemKernelDebuggerFlags',
   'SystemCodeIntegrityPolicyInformation',
   'SystemIsolatedUserModeInformation',
   'SystemHardwareSecurityTestInterfaceResultsInformation',
   'SystemSingleModuleInformation',
   'SystemAllowedCpuSetsInformation',
   'SystemVsmProtectionInformation',
   'SystemInterruptCpuSetsInformation',
   'SystemSecureBootPolicyFullInformation',
   'SystemCodeIntegrityPolicyFullInformation',
   'SystemAffinitizedInterruptProcessorInformation',
   'SystemRootSiloInformation',
   'SystemCpuSetInformation',
   'SystemCpuSetTagInformation',
   'SystemWin32WerStartCallout',
   'SystemSecureKernelProfileInformation',
   'SystemCodeIntegrityPlatformManifestInformation',
   'SystemInterruptSteeringInformation',
   'SystemSupportedProcessorArchitectures',
   'SystemMemoryUsageInformation',
   'SystemCodeIntegrityCertificateInformation',
   'SystemPhysicalMemoryInformation',
   'SystemControlFlowTransition',
   'SystemKernelDebuggingAllowed',
   'SystemActivityModerationExeState',
   'SystemActivityModerationUserSettings',
   'SystemCodeIntegrityPoliciesFullInformation',
   'SystemCodeIntegrityUnlockInformation',
   'SystemIntegrityQuotaInformation',
   'SystemFlushInformation',
   'SystemProcessorIdleMaskInformation',
   'SystemSecureDumpEncryptionInformation',
   'SystemWriteConstraintInformation',
   'SystemKernelVaShadowInformation',
   'SystemHypervisorSharedPageInformation',
   'SystemFirmwareBootPerformanceInformation',
   'SystemCodeIntegrityVerificationInformation',
   'SystemFirmwarePartitionInformation',
   'SystemSpeculationControlInformation',
   'SystemDmaGuardPolicyInformation',
   'SystemEnclaveLaunchControlInformation',
   'SystemWorkloadAllowedCpuSetsInformation',
   'SystemCodeIntegrityUnlockModeInformation',
   'SystemLeapSecondInformation',
   'SystemFlags2Information',
   'SystemSecurityModelInformation',
   'SystemCodeIntegritySyntheticCacheInformation',
   'MaxSystemInfoClass', # 210
), start=0, type=nt.CEnum)

class SYSTEM_BASIC_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 44, x64 = 64
      ('Reserved',                     nt.ULONG),
      ('TimerResolution',              nt.ULONG),
      ('PageSize',                     nt.ULONG),
      ('NumberOfPhysicalPages',        nt.ULONG),
      ('LowestPhysicalPageNumber',     nt.ULONG),
      ('HighestPhysicalPageNumber',    nt.ULONG),
      ('AllocationGranularity',        nt.ULONG),
      ('MinimumUserModeAddress',       nt.ULONG_PTR),
      ('MaximumUserModeAddress',       nt.ULONG_PTR),
      ('ActiveProcessorsAffinityMask', nt.ULONG_PTR),
      ('NumberOfProcessors',           nt.CCHAR),
   )

class SYSTEM_PROCESSOR_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 12
      ('ProcessorArchitecture', nt.USHORT),
      ('ProcessorLevel',        nt.USHORT),
      ('ProcessorRevision',     nt.USHORT),
      ('MaximumProcessors',     nt.USHORT),
      ('ProcessorFeatureBits',  nt.ULONG),
   )

class SYSTEM_PERFORMANCE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 344
      ('IdleProcessTime',           nt.LARGE_INTEGER),
      ('IoReadTransferCount',       nt.LARGE_INTEGER),
      ('IoWriteTransferCount',      nt.LARGE_INTEGER),
      ('IoOtherTransferCount',      nt.LARGE_INTEGER),
      ('IoReadOperationCount',      nt.ULONG),
      ('IoWriteOperationCount',     nt.ULONG),
      ('IoOtherOperationCount',     nt.ULONG),
      ('AvailablePages',            nt.ULONG),
      ('CommittedPages',            nt.ULONG),
      ('CommitLimit',               nt.ULONG),
      ('PeakCommitment',            nt.ULONG),
      ('PageFaultCount',            nt.ULONG),
      ('CopyOnWriteCount',          nt.ULONG),
      ('TransitionCount',           nt.ULONG),
      ('CacheTransitionCount',      nt.ULONG),
      ('DemandZeroCount',           nt.ULONG),
      ('PageReadCount',             nt.ULONG),
      ('PageReadIoCount',           nt.ULONG),
      ('CacheReadCount',            nt.ULONG),
      ('CacheIoCount',              nt.ULONG),
      ('DirtyPagesWriteCount',      nt.ULONG),
      ('DirtyWriteIoCount',         nt.ULONG),
      ('MappedPagesWriteCount',     nt.ULONG),
      ('MappedWriteIoCount',        nt.ULONG),
      ('PagedPoolPages',            nt.ULONG),
      ('NonPagedPoolPages',         nt.ULONG),
      ('PagedPoolAllocs',           nt.ULONG),
      ('PagedPoolFrees',            nt.ULONG),
      ('NonPagedPoolAllocs',        nt.ULONG),
      ('NonPagedPoolFrees',         nt.ULONG),
      ('FreeSystemPtes',            nt.ULONG),
      ('ResidentSystemCodePage',    nt.ULONG),
      ('TotalSystemDriverPages',    nt.ULONG),
      ('TotalSystemCodePages',      nt.ULONG),
      ('NonPagedPoolLookasideHits', nt.ULONG),
      ('PagedPoolLookasideHits',    nt.ULONG),
      ('AvailablePagedPoolPages',   nt.ULONG),
      ('ResidentSystemCachePage',   nt.ULONG),
      ('ResidentPagedPoolPage',     nt.ULONG),
      ('ResidentSystemDriverPage',  nt.ULONG),
      ('CcFastReadNoWait',          nt.ULONG),
      ('CcFastReadWait',            nt.ULONG),
      ('CcFastReadResourceMiss',    nt.ULONG),
      ('CcFastReadNotPossible',     nt.ULONG),
      ('CcFastMdlReadNoWait',       nt.ULONG),
      ('CcFastMdlReadWait',         nt.ULONG),
      ('CcFastMdlReadResourceMiss', nt.ULONG),
      ('CcFastMdlReadNotPossible',  nt.ULONG),
      ('CcMapDataNoWait',           nt.ULONG),
      ('CcMapDataWait',             nt.ULONG),
      ('CcMapDataNoWaitMiss',       nt.ULONG),
      ('CcMapDataWaitMiss',         nt.ULONG),
      ('CcPinMappedDataCount',      nt.ULONG),
      ('CcPinReadNoWait',           nt.ULONG),
      ('CcPinReadWait',             nt.ULONG),
      ('CcPinReadNoWaitMiss',       nt.ULONG),
      ('CcPinReadWaitMiss',         nt.ULONG),
      ('CcCopyReadNoWait',          nt.ULONG),
      ('CcCopyReadWait',            nt.ULONG),
      ('CcCopyReadNoWaitMiss',      nt.ULONG),
      ('CcCopyReadWaitMiss',        nt.ULONG),
      ('CcMdlReadNoWait',           nt.ULONG),
      ('CcMdlReadWait',             nt.ULONG),
      ('CcMdlReadNoWaitMiss',       nt.ULONG),
      ('CcMdlReadWaitMiss',         nt.ULONG),
      ('CcReadAheadIos',            nt.ULONG),
      ('CcLazyWriteIos',            nt.ULONG),
      ('CcLazyWritePages',          nt.ULONG),
      ('CcDataFlushes',             nt.ULONG),
      ('CcDataPages',               nt.ULONG),
      ('ContextSwitches ',          nt.ULONG),
      ('FirstLevelTbFills',         nt.ULONG),
      ('SecondLevelTbFills',        nt.ULONG),
      ('SystemCalls',               nt.ULONG),
      ('CcTotalDirtyPages',         nt.ULONGLONG),
      ('CcDirtyPageThreshold',      nt.ULONGLONG),
      ('ResidentAvailablePages',    nt.LONGLONG),
      ('SharedCommittedPages',      nt.ULONGLONG),
   )

class SYSTEM_TIMEOFDAY_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 48
      ('BootTime',      nt.LARGE_INTEGER),
      ('CurrentTime',   nt.LARGE_INTEGER),
      ('TimeZoneBias',  nt.LARGE_INTEGER),
      ('TimeZoneId',    nt.ULONG),
      ('Reserved',      nt.ULONG),
      ('BootTimeBias',  nt.ULONGLONG),
      ('SleepTimeBias', nt.ULONGLONG),
   )

class SYSTEM_THREAD_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 64, x64 = 80
      ('KernelTime',      nt.LARGE_INTEGER),
      ('UserTime',        nt.LARGE_INTEGER),
      ('CreateTime',      nt.LARGE_INTEGER),
      ('WaitTime',        nt.ULONG),
      ('StartAddress',    nt.PVOID),
      ('ClientId',        nt.CLIENT_ID),
      ('Priority',        nt.KPRIORITY),
      ('BasePriority',    nt.LONG),
      ('ContextSwitches', nt.ULONG),
      ('_ThreadState',    nt.ULONG), # KTHREAD_STATE
      ('_WaitReason',     nt.ULONG), # KWAIT_REASON
   )
   @property
   def ThreadState(self):
      return KTHREAD_STATE(self._ThreadState).name if self._ThreadState else None
   @property
   def WaitReason(self):
      return KWAIT_REASON(self._WaitReason).name if self._WaitReason else None

class SYSTEM_PROCESS_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 184, x64 = 256 (without SYSTEM_THREAD_INFORMATION)
      ('NextEntryOffset',              nt.ULONG),
      ('NumberOfThreads',              nt.ULONG),
      ('WorkingSetPrivateSize',        nt.LARGE_INTEGER),
      ('HardFaultCount',               nt.ULONG),
      ('NumberOfThreadsHighWatermark', nt.ULONG),
      ('CycleTime',                    nt.ULONGLONG),
      ('CreateTime',                   nt.LARGE_INTEGER),
      ('UserTime',                     nt.LARGE_INTEGER),
      ('KernelTime',                   nt.LARGE_INTEGER),
      ('ImageName',                    nt.UNICODE_STRING),
      ('BasePriority',                 nt.KPRIORITY),
      ('UniqueProcessId',              nt.HANDLE),
      ('InheritedFromUniqueProcessId', nt.HANDLE),
      ('HandleCount',                  nt.ULONG),
      ('SessionId',                    nt.ULONG),
      ('UniqueProcessKey',             nt.ULONG_PTR),
      ('PeakVirtualSize',              nt.SIZE_T),
      ('VirtualSize',                  nt.SIZE_T),
      ('PageFaultCount',               nt.ULONG),
      ('PeakWorkingSetSize',           nt.SIZE_T),
      ('WorkingSetSize',               nt.SIZE_T),
      ('QuotaPeakPagedPoolUsage',      nt.SIZE_T),
      ('QuotaPagedPoolUsage',          nt.SIZE_T),
      ('QuotaPeakNonPagedPoolUsage',   nt.SIZE_T),
      ('QuotaNonPagedPoolUsage',       nt.SIZE_T),
      ('PagefileUsage',                nt.SIZE_T),
      ('PeakPagefileUsage',            nt.SIZE_T),
      ('PrivatePageCount',             nt.SIZE_T),
      ('ReadOperationCount',           nt.LARGE_INTEGER),
      ('WriteOperationCount',          nt.LARGE_INTEGER),
      ('OtherOperationCount',          nt.LARGE_INTEGER),
      ('ReadTransferCount',            nt.LARGE_INTEGER),
      ('WriteTransferCount',           nt.LARGE_INTEGER),
      ('OtherTransferCount',           nt.LARGE_INTEGER),
      ('Threads',                      SYSTEM_THREAD_INFORMATION * 1),
   )

class SYSTEM_CALL_COUNT_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 8
      ('Length',         nt.ULONG),
      ('NumberOfTables', nt.ULONG),
   )

class SYSTEM_DEVICE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 24
      ('NumberOfDisks',         nt.ULONG),
      ('NumberOfFloppies',      nt.ULONG),
      ('NumberOfCdRoms',        nt.ULONG),
      ('NumberOfTapes',         nt.ULONG),
      ('NumberOfSerialPorts',   nt.ULONG),
      ('NumberOfParallelPorts', nt.ULONG),
   )

class SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 48
      ('IdleTime',       nt.LARGE_INTEGER),
      ('KernelTime',     nt.LARGE_INTEGER),
      ('UserTime',       nt.LARGE_INTEGER),
      ('DpcTime',        nt.LARGE_INTEGER),
      ('InterruptTime',  nt.LARGE_INTEGER),
      ('InterruptCount', nt.ULONG),
   )

class SYSTEM_FLAGS_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 4
      ('Flags', nt.ULONG),
   )

class SYSTEM_CALL_TIME_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 16
      ('Length',      nt.ULONG),
      ('TotalCalls',  nt.ULONG),
      ('TimeOfCalls', nt.LARGE_INTEGER * 1),
   )

class RTL_PROCESS_LOCK_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 36, x64 = 48
      ('Address',                  nt.PVOID),
      ('Type',                     nt.USHORT),
      ('CreatorBackTraceIndex',    nt.USHORT),
      ('OwningThread',             nt.HANDLE),
      ('LockCount',                nt.LONG),
      ('ContentionCount',          nt.ULONG),
      ('EntryCount',               nt.ULONG),
      ('RecursionCount',           nt.LONG),
      ('NumberOfWaitingShared',    nt.ULONG),
      ('NumberOfWaitingExclusive', nt.ULONG),
   )

class RTL_PROCESS_LOCKS(nt.CStruct):
   _fields_ = ( # x86 = 40, x64 = 56
      ('NumberOfLocks', nt.ULONG),
      ('Locks',         RTL_PROCESS_LOCK_INFORMATION * 1),
   )

class RTL_PROCESS_BACKTRACE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 140, x64 = 272
      ('SymbolicBackTrace', nt.PSTR),
      ('TraceCount',        nt.ULONG),
      ('Index',             nt.USHORT),
      ('Depth',             nt.USHORT),
      ('BackTrace',         nt.PVOID * 32),
   )

class RTL_PROCESS_BACKTRACES(nt.CStruct):
   _fields_ = ( # x86 = 156, x64 = 296
      ('CommittedMemory',          nt.ULONG_PTR),
      ('ReservedMemory',           nt.ULONG_PTR),
      ('NumberOfBackTraceLookups', nt.ULONG),
      ('NumberOfBackTraces',       nt.ULONG),
      ('BackTraces',               RTL_PROCESS_BACKTRACE_INFORMATION * 1),
   )

class SYSTEM_HANDLE_TABLE_ENTRY_INFO(nt.CStruct):
   _fields_ = ( # x86 = 16, x64 = 24
      ('UniqueProcessId',       nt.USHORT),
      ('CreatorBackTraceIndex', nt.USHORT),
      ('ObjectTypeIndex',       nt.UCHAR),
      ('HandleAttributes',      nt.UCHAR),
      ('HandleValue',           nt.USHORT),
      ('Object',                nt.PVOID),
      ('GrantedAccess',         nt.ULONG),
   )

class SYSTEM_HANDLE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 20, x64 = 32
      ('NumberOfHandles', nt.ULONG),
      ('Handles',         SYSTEM_HANDLE_TABLE_ENTRY_INFO * 1),
   )

class SYSTEM_OBJECTTYPE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 56, x64 = 64
      ('NextEntryOffset',   nt.ULONG),
      ('NumberOfObjects',   nt.ULONG),
      ('NumberOfHandles',   nt.ULONG),
      ('TypeIndex',         nt.ULONG),
      ('InvalidAttributes', nt.ULONG),
      ('GenericMapping',    nt.GENERIC_MAPPING),
      ('ValidAccessMask',   nt.ULONG),
      ('PoolType',          nt.ULONG),
      ('SecurityRequired',  nt.BOOLEAN),
      ('WaitableObject',    nt.BOOLEAN),
      ('TypeName',          nt.UNICODE_STRING),
   )

class SYSTEM_OBJECT_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 48, x64 = 80
      ('NextEntryOffset',       nt.ULONG),
      ('Object',                nt.PVOID),
      ('CreatorUniqueProcess',  nt.HANDLE),
      ('CreatorBackTraceIndex', nt.USHORT),
      ('Flags',                 nt.USHORT),
      ('PointerCount',          nt.LONG),
      ('HandleCount',           nt.LONG),
      ('PagedPoolCharge',       nt.ULONG),
      ('NonPagedPoolCharge',    nt.ULONG),
      ('ExclusiveProcessId',    nt.HANDLE),
      ('SecurityDescriptor',    nt.PVOID),
      ('NameInfo',              nt.OBJECT_NAME_INFORMATION),
   )

class SYSTEM_PAGEFILE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 24, x64 = 32
      ('NextEntryOffset', nt.ULONG),
      ('TotalSize',       nt.ULONG),
      ('TotalInUse',      nt.ULONG),
      ('PeakUsage',       nt.ULONG),
      ('PageFileName',    nt.UNICODE_STRING),
   )

class SYSTEM_VDM_INSTEMUL_INFO(nt.CStruct):
   _fields_ = ( # x86 = x64 = 136
      ('SegmentNotPresent',  nt.ULONG),
      ('VdmOpcode0F',        nt.ULONG),
      ('OpcodeESPrefix',     nt.ULONG),
      ('OpcodeCSPrefix',     nt.ULONG),
      ('OpcodeSSPrefix',     nt.ULONG),
      ('OpcodeDSPrefix',     nt.ULONG),
      ('OpcodeFSPrefix',     nt.ULONG),
      ('OpcodeGSPrefix',     nt.ULONG),
      ('OpcodeOPER32Prefix', nt.ULONG),
      ('OpcodeADDR32Prefix', nt.ULONG),
      ('OpcodeINSB',         nt.ULONG),
      ('OpcodeINSW',         nt.ULONG),
      ('OpcodeOUTSB',        nt.ULONG),
      ('OpcodeOUTSW',        nt.ULONG),
      ('OpcodePUSHF',        nt.ULONG),
      ('OpcodePOPF',         nt.ULONG),
      ('OpcodeINTnn',        nt.ULONG),
      ('OpcodeINTO',         nt.ULONG),
      ('OpcodeIRET',         nt.ULONG),
      ('OpcodeINBimm',       nt.ULONG),
      ('OpcodeINWimm',       nt.ULONG),
      ('OpcodeOUTBimm',      nt.ULONG),
      ('OpcodeOUTWimm',      nt.ULONG),
      ('OpcodeINB',          nt.ULONG),
      ('OpcodeINW',          nt.ULONG),
      ('OpcodeOUTB',         nt.ULONG),
      ('OpcodeOUTW',         nt.ULONG),
      ('OpcodeLOCKPrefix',   nt.ULONG),
      ('OpcodeREPNEPrefix',  nt.ULONG),
      ('OpcodeREPPrefix',    nt.ULONG),
      ('OpcodeHLT',          nt.ULONG),
      ('OpcodeCLI',          nt.ULONG),
      ('OpcodeSTI',          nt.ULONG),
      ('BopCount',           nt.ULONG),
   )

class SYSTEM_FILECACHE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 36, x64 = 64
      ('CurrentSize',                           nt.SIZE_T),
      ('PeakSize',                              nt.SIZE_T),
      ('PageFaultCount',                        nt.ULONG),
      ('MinimumWorkingSet',                     nt.SIZE_T),
      ('MaximumWorkingSet',                     nt.SIZE_T),
      ('CurrentSizeIncludingTransitionInPages', nt.SIZE_T),
      ('PeakSizeIncludingTransitionInPages',    nt.SIZE_T),
      ('TransitionRePurposeCount',              nt.ULONG),
      ('Flags',                                 nt.ULONG),
   )

class SYSTEM_POOLTAG_UNION(Union):
   _fields_ = (
      ('Tag',      nt.UCHAR * 4),
      ('TagUlong', nt.ULONG),
   )

class SYSTEM_POOLTAG(nt.CStruct):
   _fields_ = ( # x86 = 28, x64 = 40
      ('Tag',            SYSTEM_POOLTAG_UNION),
      ('PagedAllocs',    nt.ULONG),
      ('PagedFrees',     nt.ULONG),
      ('PagedUsed',      nt.SIZE_T),
      ('NonPagedAllocs', nt.ULONG),
      ('NonPagedFrees',  nt.ULONG),
      ('NonPagedUsed',   nt.SIZE_T),
   )

class SYSTEM_POOLTAG_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 32, x64 = 48
      ('Count',   nt.ULONG),
      ('TagInfo', SYSTEM_POOLTAG * 1),
   )

class SYSTEM_INTERRUPT_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 24
      ('ContextSwitches', nt.ULONG),
      ('DpcCount',        nt.ULONG),
      ('DpcRate',         nt.ULONG),
      ('TimeIncrement',   nt.ULONG),
      ('DpcBypassCount',  nt.ULONG),
      ('ApcBypassCount',  nt.ULONG),
   )

class SYSTEM_DPC_BEHAVIOR_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 20
      ('Spare',              nt.ULONG),
      ('DpcQueueDepth',      nt.ULONG),
      ('MinimumDpcRate',     nt.ULONG),
      ('AdjustDpcThreshold', nt.ULONG),
      ('IdealDpcRate',       nt.ULONG),
   )

class SYSTEM_QUERY_TIME_ADJUST_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 12
      ('TimeAdjustment', nt.ULONG),
      ('TimeIncrement',  nt.ULONG),
      ('Enable',         nt.BOOLEAN),
   )

class SYSTEM_EXCEPTION_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 16
      ('AlignmentFixupCount',    nt.ULONG),
      ('ExceptionDispatchCount', nt.ULONG),
      ('FloatingEmulationCount', nt.ULONG),
      ('ByteWordEmulationCount', nt.ULONG),
   )

SYSTEM_CRASH_DUMP_CONFIGURATION_CLASS = IntEnum('SYSTEM_CRASH_DUMP_CONFIGURATION_CLASS', (
   'SystemCrashDumpDisable',
   'SystemCrashDumpReconfigure',
   'SystemCrashDumpInitializationComplete',
), start=0)

class SYSTEM_CRASH_DUMP_STATE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 4
      ('_CrashDumpConfigurationClass', nt.ULONG),
   )
   @property
   def CrashDumpConfigurationClass(self):
      return SYSTEM_CRASH_DUMP_CONFIGURATION_CLASS(
         self._CrashDumpConfigurationClass
      ).name if self._CrashDumpConfigurationClass else None

class SYSTEM_KERNEL_DEBUGGER_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 2
      ('KernelDebuggerEnabled',    nt.BOOLEAN),
      ('KernelDebuggerNotPresent', nt.BOOLEAN),
   )

class SYSTEM_CONTEXT_SWITCH_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 48
      ('ContextSwitches', nt.ULONG),
      ('FindAny',         nt.ULONG),
      ('FindLast',        nt.ULONG),
      ('FindIdeal',       nt.ULONG),
      ('IdleAny',         nt.ULONG),
      ('IdleCurrent',     nt.ULONG),
      ('IdleLast',        nt.ULONG),
      ('IdleIdeal',       nt.ULONG),
      ('PreemptAny',      nt.ULONG),
      ('PreemptCurrent',  nt.ULONG),
      ('PreemptLast',     nt.ULONG),
      ('SwitchToIdle',    nt.ULONG),
   )

class SYSTEM_REGISTRY_QUOTA_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 12, x64 = 16
      ('RegistryQuotaAllowed', nt.ULONG),
      ('RegistryQuotaUsed',    nt.ULONG),
      ('PagedPoolSize',        nt.SIZE_T),
   )

class SYSTEM_PROCESSOR_IDLE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 48
      ('IdleTime',      nt.ULONGLONG),
      ('C1Time',        nt.ULONGLONG),
      ('C2Time',        nt.ULONGLONG),
      ('C3Time',        nt.ULONGLONG),
      ('C1Transitions', nt.ULONG),
      ('C2Transitions', nt.ULONG),
      ('C3Transitions', nt.ULONG),
      ('Padding',       nt.ULONG),
   )

class SYSTEM_LEGACY_DRIVER_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 12, x64 = 24
      ('VetoType', nt.ULONG),
      ('VetoList', nt.UNICODE_STRING),
   )

class SYSTEM_LOOKASIDE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 32
      ('CurrentDepth',   nt.USHORT),
      ('MaximumDepth',   nt.USHORT),
      ('TotalAllocates', nt.ULONG),
      ('AllocateMisses', nt.ULONG),
      ('TotalFrees',     nt.ULONG),
      ('FreeMisses',     nt.ULONG),
      ('Type',           nt.ULONG),
      ('Tag',            nt.ULONG),
      ('Size',           nt.ULONG),
   )

class SYSTEM_RANGE_START_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 4, x64 = 8
      ('SystemRangeStart', nt.PVOID),
   )

class SYSTEM_VERIFIER_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 120, x64 = 144
      ('NextEntryOffset',                 nt.ULONG),
      ('Level',                           nt.ULONG),
      ('RuleClasses',                     nt.ULONG * 2),
      ('TriageContext',                   nt.ULONG),
      ('AreAllDriversBeingVerified',      nt.ULONG),
      ('DriverName',                      nt.UNICODE_STRING),
      ('RaiseIrqls',                      nt.ULONG),
      ('AcquireSpinLocks',                nt.ULONG),
      ('SynchronizeExecutions',           nt.ULONG),
      ('AllocationsAttempted',            nt.ULONG),
      ('AllocationsSucceeded',            nt.ULONG),
      ('AllocationsSucceededSpecialPool', nt.ULONG),
      ('AllocationsWithNoTag',            nt.ULONG),
      ('TrimRequests',                    nt.ULONG),
      ('Trims',                           nt.ULONG),
      ('AllocationsFailed',               nt.ULONG),
      ('AllocationsFailedDeliberately',   nt.ULONG),
      ('Loads',                           nt.ULONG),
      ('Unloads',                         nt.ULONG),
      ('UnTrackedPool',                   nt.ULONG),
      ('CurrentPagedPoolAllocations',     nt.ULONG),
      ('CurrentNonPagedPoolAllocations',  nt.ULONG),
      ('PeakPagedPoolAllocations',        nt.ULONG),
      ('PeakNonPagedPoolAllocations',     nt.ULONG),
      ('PagedPoolUsageInBytes',           nt.SIZE_T),
      ('NonPagedPoolUsageInBytes',        nt.SIZE_T),
      ('PeakPagedPoolUsageInBytes',       nt.SIZE_T),
      ('PeakNonPagedPoolUsageInBytes',    nt.SIZE_T),
   )

class SYSTEM_SESSION_PROCESS_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 12, x64 = 16
      ('SessionId', nt.ULONG),
      ('SizeOfBuf', nt.ULONG),
      ('Buffer',    nt.PVOID),
   )

class SYSTEM_NUMA_INFORMATION_UNION(Union):
   _fields_ = (
      ('ActiveProcessorsGroupAffinity', nt.GROUP_AFFINITY * 64),
      ('AvailableMemory',               nt.ULONGLONG * 64),
      ('Pad',                           nt.ULONGLONG * 128),
   )

class SYSTEM_NUMA_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 264, x64 = 1032
      ('HighestNodeNumber', nt.ULONG),
      ('Reserved',          nt.ULONG),
      ('MaximumNodeCount',  SYSTEM_NUMA_INFORMATION_UNION),
   )

class SYSTEM_PROCESSOR_POWER_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 80
      ('CurrentFrequency',          nt.UCHAR),
      ('ThermalLimitFrequency',     nt.UCHAR),
      ('ConstantThrottleFrequency', nt.UCHAR),
      ('DegradedThrottleFrequency', nt.UCHAR),
      ('LastBusyFrequency',         nt.UCHAR),
      ('LastC3Frequency',           nt.UCHAR),
      ('LastAdjustedBusyFrequency', nt.UCHAR),
      ('ProcessorMinThrottle',      nt.UCHAR),
      ('ProcessorMaxThrottle',      nt.UCHAR),
      ('NumberOfFrequencies',       nt.ULONG),
      ('PromotionCount',            nt.ULONG),
      ('DemotionCount',             nt.ULONG),
      ('ErrorCount',                nt.ULONG),
      ('RetryCount',                nt.ULONG),
      ('CurrentFrequencyTime',      nt.ULONGLONG),
      ('CurrentProcessorTime',      nt.ULONGLONG),
      ('CurrentProcessorIdleTime',  nt.ULONGLONG),
      ('LastProcessorTime',         nt.ULONGLONG),
      ('LastProcessorIdleTime',     nt.ULONGLONG),
      ('Energy',                    nt.ULONGLONG),
   )

class SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX(nt.CStruct):
   _fields_ = ( # x86 = 28, x64 = 40
      ('Object',                nt.PVOID),
      ('UniqueProcessId',       nt.ULONG_PTR),
      ('HandleValue',           nt.ULONG_PTR),
      ('GrantedAccess',         nt.ULONG),
      ('CreatorBackTraceIndex', nt.USHORT),
      ('ObjectTypeIndex',       nt.USHORT),
      ('HandleAttributes',      nt.ULONG),
      ('Reserved',              nt.ULONG),
   )

class SYSTEM_HANDLE_INFORMATION_EX(nt.CStruct):
   _fields_ = ( # x86 = 36, x64 = 56
      ('NumberOfHandles', nt.ULONG_PTR),
      ('Reserved',        nt.ULONG_PTR),
      ('Handles',         SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX * 1),
   )

class SYSTEM_BIGPOOL_ENTRY_MEMORY(Union):
   _fields_ = (
      ('VirtualAddress', nt.PVOID),
      ('NonPaged',       nt.ULONG_PTR, 1),
   )

class SYSTEM_BIGPOOL_ENTRY_TAG(Union):
   _fields_ = (
      ('Tag',      nt.UCHAR * 4),
      ('TagUlong', nt.ULONG),
   )

class SYSTEM_BIGPOOL_ENTRY(nt.CStruct):
   _fields_ = ( # x86 = 12, x64 = 24
      ('Memory',      SYSTEM_BIGPOOL_ENTRY_MEMORY),
      ('SizeInBytes', nt.SIZE_T),
      ('Tag',         SYSTEM_BIGPOOL_ENTRY_TAG),
   )

class SYSTEM_BIGPOOL_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 16, x64 = 32
      ('Count',         nt.ULONG),
      ('AllocatedInfo', SYSTEM_BIGPOOL_ENTRY * 1),
   )

class SYSTEM_POOLTAG_TAG(Union):
   _fields_ = (
      ('Tag',      nt.UCHAR * 4),
      ('TagUlong', nt.ULONG),
   )

class SYSTEM_POOLTAG(nt.CStruct):
   _fields_ = ( # x86 = 28, x64 = 40
      ('Tag',            SYSTEM_POOLTAG_TAG),
      ('PagedAllocs',    nt.ULONG),
      ('PagedFrees',     nt.ULONG),
      ('PagedUsed',      nt.SIZE_T),
      ('NonPagedAllocs', nt.ULONG),
      ('NonPagedFrees',  nt.ULONG),
      ('NonPagedUsed',   nt.SIZE_T),
   )

class SYSTEM_SESSION_POOLTAG_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 40, x64 = 56
      ('NextEntryOffset', nt.SIZE_T),
      ('SessionId',       nt.ULONG),
      ('Count',           nt.ULONG),
      ('TagInfo',         SYSTEM_POOLTAG),
   )

class SYSTEM_SESSION_MAPPED_VIEW_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 20, x64 = 32
      ('NextEntryOffset',                  nt.SIZE_T),
      ('SessionId',                        nt.ULONG),
      ('ViewFailures',                     nt.ULONG),
      ('NumberOfBytesAvailable',           nt.SIZE_T),
      ('NumberOfBytesAvailableContiguous', nt.SIZE_T),
   )

WATCHDOG_INFORMATION_CLASS = IntEnum('WATCHDOG_INFORMATION_CLASS', (
   'WdInfoTimeoutValue',
   'WdInfoResetTimer',
   'WdInfoStopTimer',
   'WdInfoStartTimer',
   'WdInfoTriggerAction',
   'WdInfoState',
   'WdInfoTriggerReset',
   'WdInfoNop',
   'WdInfoGeneratedLastReset',
   'WdInfoInvalid',
), start=0)

class SYSTEM_WATCHDOG_TIMER_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 8
      ('WdInfoClass', nt.ULONG), # WATCHDOG_INFORMATION_CLASS (kernel-mode)
      ('DataValue',   nt.ULONG),
   )

class SYSTEM_LOGICAL_PROCESSOR_INFORMATION_UNION(Union):
   _fields_ = (
      ('ProcessorCore', nt.PROCESSORCORE),
      ('NumaNode',      nt.NUMANODE),
      ('Cache',         nt.CACHE_DESCRIPTOR),
      ('Reserved',      nt.ULONGLONG * 2),
   )

class SYSTEM_LOGICAL_PROCESSOR_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = 24, x64 = 32
      ('ProcessorMask', nt.ULONG_PTR),
      ('_Relationship', nt.ULONG_PTR),
      ('ProcessorInfo', SYSTEM_LOGICAL_PROCESSOR_INFORMATION_UNION),
   )
   @property
   def Relationship(self):
      return nt.LOGICAL_PROCESSOR_RELATIONSHIP(self._Relationship).name if self._Relationship else None

SYSTEM_FIRMWARE_TABLE_ACTION = IntEnum('SYSTEM_FIRMWARE_TABLE_ACTION', (
   'SystemFirmwareTable_Enumerate',
   'SystemFirmwareTable_Get',
), start=0)

class SYSTEM_FIRMWARE_TABLE_INFORMATION(nt.CStruct):
   _fields_ = ( # x86 = x64 = 20
      ('ProviderSignature', nt.ULONG),
      ('_Action',           nt.ULONG),
      ('TableID',           nt.ULONG),
      ('TableBufferLength', nt.ULONG),
      ('TableBuffer',       nt.UCHAR * 1),
   )
   @property
   def Action(self):
      return SYSTEM_FIRMWARE_TABLE_ACTION(self._Action).name if self._Action else None
# ====================================================================================
NtQuerySystemInformation.restype  = nt.NTSTATUS
NtQuerySystemInformation.argtypes = [SYSTEM_INFORMATION_CLASS, nt.PVOID, nt.ULONG, nt.PULONG]

NtQueryTimerResolution.restype    = nt.NTSTATUS
NtQueryTimerResolution.argtypes   = [nt.PULONG, nt.PULONG, nt.PULONG]
