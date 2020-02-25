import wintypes as nt

from ctypes   import Structure, windll
from enum     import IntEnum
from ntkeapi  import KTHREAD_STATE, KWAIT_REASON
# ====================================================================================
NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
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
   'SystemFileCacheInformation',
   'SystemPoolTagInformation',
   'SystemInterruptInformation',
   'SystemDpcBehaviorInformation',
   'SystemFullMemoryInformation',
   'SystemLoadGdiDriverInformation',
   'SystemUnloadGdiDriverInformation',
   'SystemTimeAdjustmentInformation',
   'SystemSummaryMemoryInformation',
   'SystemMirrorMemoryInformation',
   'SystemPerformanceTraceInformation',
   'SystemObsolete0',
   'SystemExceptionInformation',
   'SystemCrashDumpStateInformation',
   'SystemKernelDebuggerInformation',
   'SystemContextSwitchInformation',
   'SystemRegistryQuotaInformation',
   'SystemExtendServiceTableInformation',
   'SystemPrioritySeperation',
   'SystemVerifierAddDriverInformation',
   'SystemVerifierRemoveDriverInformation',
   'SystemProcessorIdleInformation',
   'SystemLegacyDriverInformation',
   'SystemCurrentTimeZoneInformation',
   'SystemLookasideInformation',
   'SystemTimeSlipNotification',
   'SystemSessionCreate',
   'SystemSessionDetach',
   'SystemSessionInformation',
   'SystemRangeStartInformation',
   'SystemVerifierInformation',
   'SystemVerifierThunkExtend',
   'SystemSessionProcessInformation',
   'SystemLoadGdiDriverInSystemSpace',
   'SystemNumaProcessorMap',
   'SystemPrefetcherInformation',
   'SystemExtendedProcessInformation',
   'SystemRecommendedSharedDataAlignment',
   'SystemComPlusPackage',
   'SystemNumaAvailableMemory',
   'SystemProcessorPowerInformation',
   'SystemEmulationBasicInformation',
   'SystemEmulationProcessorInformation',
   'SystemExtendedHandleInformation',
   'SystemLostDelayedWriteInformation',
   'SystemBigPoolInformation',
   'SystemSessionPoolTagInformation',
   'SystemSessionMappedViewInformation',
   'SystemHotpatchInformation',
   'SystemObjectSecurityMode',
   'SystemWatchdogTimerHandler',
   'SystemWatchdogTimerInformation',
   'SystemLogicalProcessorInformation',
   'SystemWow64SharedInformationObsolete',
   'SystemRegisterFirmwareTableInformationHandler',
   'SystemFirmwareTableInformation',
   'SystemModuleInformationEx',
   'SystemVerifierTriageInformation',
   'SystemSuperfetchInformation',
   'SystemMemoryListInformation',
   'SystemFileCacheInformationEx',
   'SystemThreadPriorityClientIdInformation',
   'SystemProcessorIdleCycleTimeInformation',
   'SystemVerifierCancellationInformation',
   'SystemProcessorPowerInformationEx',
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
   'SystemPrefetchPatchInformation',
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
   'SystemNativeBasicInformation',
   'SystemErrorPortTimeouts',
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
# ====================================================================================
NtQuerySystemInformation.restype  = nt.NTSTATUS
NtQuerySystemInformation.argtypes = [SYSTEM_INFORMATION_CLASS, nt.PVOID, nt.ULONG, nt.PULONG]
