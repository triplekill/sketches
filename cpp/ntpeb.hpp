#pragma once

typedef struct _PEB_LDR_DATA {
   ULONG   Length;
   BOOLEAN Initialized;
   HANDLE  SsHandle;
   LIST_ENTRY InLoadOrderModuleList;
   LIST_ENTRY InMemoryOrderModuleList;
   LIST_ENTRY InInitializationOrderModuleList;
   PVOID   EntryInProgress;
   BOOLEAN ShutdownInProgress;
   PVOID   ShutdownThreadId;
} PEB_LDR_DATA, *PPEB_LDR_DATA;

typedef struct _RTL_DRIVE_LETTER_CURDIR {
   USHORT Flags;
   USHORT Length;
   ULONG  TimeStamp;
   STRING DosPath;
} RTL_DRIVE_LETTER_CURDIR, *PRTL_DRIVE_LETTER_CURDIR;

typedef struct _RTL_USER_PROCESS_PARAMETERS {
   ULONG  MaximumLength;
   ULONG  Length;
   ULONG  Flags;
   ULONG  DebugFlags;
   HANDLE ConsoleHandle;
   ULONG  ConsoleFlags;
   HANDLE StandardInput;
   HANDLE StandardOutput;
   HANDLE StandardError;
   CURDIR CurrentDirectory;
   UNICODE_STRING DllPath;
   UNICODE_STRING ImagePathName;
   UNICODE_STRING CommandLine;
   PVOID  Environment;
   ULONG  StartingX;
   ULONG  StartingY;
   ULONG  CountX;
   ULONG  CountY;
   ULONG  CountCharsX;
   ULONG  CountCharsY;
   ULONG  FillAttribute;
   ULONG  WindowFlags;
   ULONG  ShowWindowFlags;
   UNICODE_STRING WindowTitle;
   UNICODE_STRING DesktopInfo;
   UNICODE_STRING ShellInfo;
   UNICODE_STRING RuntimeData;
   RTL_DRIVE_LETTER_CURDIR CurrentDirectores[32];
   SIZE_T EnvironmentSize;
   ULONG_PTR EnvironmentVersion;
   PVOID  PackageDependencyData;
   ULONG  ProcessGroupId;
   ULONG  LoaderThreads;
   UNICODE_STRING RedirectionDllName;
   UNICODE_STRING HeapPartitionName;
   PULONGLONG DefaultThreadpoolCpuSetMasks;
   ULONG  DefaultThreadpoolCpuSetMaskCount;
} RTL_USER_PROCESS_PARAMETERS, *PRTL_USER_PROCESS_PARAMETERS;

typedef struct _RTL_CRITICAL_SECTION_DEBUG {
   USHORT Type;
   USHORT CreatorBackTraceIndex;
   struct RTL_CRITICAL_SECTION *CriticalSection;
   LIST_ENTRY ProcessLocksList;
   ULONG  EntryCount;
   ULONG  ContentionCount;
   ULONG  Flags;
   USHORT CreatorBackTraceIndexHigh;
   USHORT SpareUSHORT;
} RTL_CRITICAL_SECTION_DEBUG, *PRTL_CRITICAL_SECTION_DEBUG;

typedef struct _RTL_CRITICAL_SECTION {
   PRTL_CRITICAL_SECTION_DEBUG DebugInfo;
   LONG   LockCount;
   LONG   RecursionCount;
   HANDLE OwningThread;
   HANDLE LockSemaphore;
   SIZE_T SpinCount;
} RTL_CRITICAL_SECTION, *PRTL_CRITICAL_SECTION;

typedef struct _API_SET_NAMESPACE {
   ULONG Version;
   ULONG Size;
   ULONG Flags;
   ULONG Count;
   ULONG EntryOffset;
   ULONG HashOffset;
   ULONG HashFactor;
} API_SET_NAMESPACE, *PAPI_SET_NAMESPACE;

typedef struct _SINGLE_LIST_ENTRY {
   struct SINGLE_LIST_ENTRY *Next;
} SINGLE_LIST_ENTRY, *PSINGLE_LIST_ENTRY;

typedef struct _SLIST_HEADER {
   union {
      ULONGLONG Alignment;
#ifdef _M_X64
      ULONGLONG HeaderX64; // anonymous tag
#else
      struct {
         SINGLE_LIST_ENTRY Next;
         USHORT Depth;
         USHORT CpuId;
      };
#endif
   };
#ifdef _M_X64
   ULONGLONG Region;
#endif
} SLIST_HEADER, *PSLIST_HEADER;

typedef VOID (__stdcall *PPS_POST_PROCESS_INIT_ROUTINE)(VOID);

typedef struct _ACTIVATION_CONTEXT_DATA {
} ACTIVATION_CONTEXT_DATA, *PACTIVATION_CONTEXT_DATA;

typedef struct _ASSEMBLY_STORAGE_MAP {
} ASSEMBLY_STORAGE_MAP, *PASSEMBLY_STORAGE_MAP;

typedef struct _LEAP_SECOND_DATA {
   BOOLEAN Enabled;
   UCHAR   Padding[3];
   ULONG   Count;
   LARGE_INTEGER Data[1];
} LEAP_SECOND_DATA, *PLEAP_SECOND_DATA;

typedef struct _PEB {
   BOOLEAN InheritedAddressSpace;
   BOOLEAN ReadImageFileExecOptions;
   BOOLEAN BeingDebugged;
   union {
      BOOLEAN BitField;
      struct {
         BOOLEAN ImageUsesLargePages : 1;
         BOOLEAN IsProtectedProcess : 1;
         BOOLEAN IsImageDynamicallyRelocated : 1;
         BOOLEAN SkipPatchingUser32Forwarders : 1;
         BOOLEAN IsPackagedProcess : 1;
         BOOLEAN IsAppContainer : 1;
         BOOLEAN IsProtectedProcessLight : 1;
         BOOLEAN IsLongPathAwareProcess : 1;
      };
   };
#ifdef _M_X64
   UCHAR Padding0[4];
#endif
   HANDLE Mutant;
   PVOID  ImageBaseAddress;
   PPEB_LDR_DATA Ldr;
   PRTL_USER_PROCESS_PARAMETERS ProcessParameters;
   PVOID  SubSystemData;
   PVOID  ProcessHeap;
   PRTL_CRITICAL_SECTION FastPebLock;
   PSLIST_HEADER AtlThunkSListPtr;
   PVOID  IFEOKey;
   union {
      ULONG CrossProcessFlags;
      struct {
         ULONG ProcessInJob : 1;
         ULONG ProcessInitializing : 1;
         ULONG ProcessUsingVEH : 1;
         ULONG ProcessUsingVCH : 1;
         ULONG ProcessUsingFTH : 1;
         ULONG ProcessPreviouslyThrottled : 1;
         ULONG ProcessCurrentlyThrottled : 1;
         ULONG ProcessImagesHotPatched : 1;
         ULONG ReservedBits0 : 24;
      };
   };
#ifdef _M_X64
   UCHAR Padding1[4];
#endif
   union {
      PVOID KernelCallbackTable;
      PVOID UserSharedInfoPtr;
   };
   ULONG  SystemReserved;
   ULONG  AtlThunkSListPtr32;
   PAPI_SET_NAMESPACE ApiSetMap; // PVOID ApiSetMap;
   ULONG  TlsExpansionCounter;
#ifdef _M_X64
   UCHAR  Padding2[4];
#endif
   PVOID  TlsBitmap;
   ULONG  TlsBitmapBits[2];
   PVOID  ReadOnlySharedMemoryBase;
   PVOID  SharedData;
   PVOID  *ReadOnlyStaticServerData;
   PVOID  AnsiCodePageData;
   PVOID  OemCodePageData;
   PVOID  UnicodeCaseTableData;
   ULONG  NumberOfProcessors;
   ULONG  NtGlobalFlag;
   LARGE_INTEGER CriticalSectionTimeout;
   SIZE_T HeapSegmentReserve;
   SIZE_T HeapSegmentCommit;
   SIZE_T HeapDeCommitTotalFreeThreshold;
   SIZE_T HeapDeCommitFreeBlockThreshold;
   ULONG  NumberOfHeaps;
   ULONG  MaximumNumberOfHeaps;
   PHEAP  ProcessHeaps; // PVOID *ProcessHeaps;
   PVOID  GdiSharedHandleTable;
   PVOID  ProcessStarterHelper;
   ULONG  GdiDCAttributeList;
#ifdef _M_X64
   UCHAR Padding3[4];
#endif
   PRTL_CRITICAL_SECTION LoaderLock;
   ULONG  OSMajorVersion;
   ULONG  OSMinorVersion;
   USHORT OSBuildNumber;
   USHORT OSCSDVersion;
   ULONG  OSPlatformId;
   ULONG  ImageSubsystem;
   ULONG  ImageSubsystemMajorVersion;
   ULONG  ImageSubsystemMinorVersion;
#ifdef _M_X64
   UCHAR Padding4[4];
#endif
   ULONG_PTR ActiveProcessAffinityMask;
   ULONG  GdiHandleBuffer[60];
   PPS_POST_PROCESS_INIT_ROUTINE PostProcessInitRoutine;
   PVOID  TlsExpansionBitmap;
   ULONG  TlsExpansionBitmapBits[32];
   ULONG  SessionId;
#ifdef _M_X64
   UCHAR Padding5[4];
#endif
   ULARGE_INTEGER AppCompatFlags;
   ULARGE_INTEGER AppCompatFlagsUser;
   PVOID  pShimData;
   PVOID  AppCompatInfo;
   UNICODE_STRING CSDVersion;
   PACTIVATION_CONTEXT_DATA ActivationContextData;
   PASSEMBLY_STORAGE_MAP ProcessAssemblyStorageMap;
   PACTIVATION_CONTEXT_DATA SystemDefaultActivationContextData;
   PASSEMBLY_STORAGE_MAP SystemAssemblyStorageMap;
   SIZE_T MinimumStackCommit : Uint8B
   PVOID  SparePointers[4];
   ULONG  SpareUlongs[5];
   PVOID  WerRegistrationData;
   PVOID  WerShipAssertPtr;
   PVOID  pUnused;
   PVOID  pImageHeaderHash;
   union {
      ULONG TracingFlags;
      struct {
         ULONG HeapTracingEnabled : 1;
         ULONG CritSecTracingEnabled : 1;
         ULONG LibLoaderTracingEnabled : 1;
         ULONG SpareTracingBits : 29;
      };
   };
#ifdef _M_X64
   UCHAR Padding6[4];
#endif
   ULONGLONG CsrServerReadOnlySharedMemoryBase;
   ULONG_PTR TppWorkerpListLock; // PRTL_CRITICAL_SECTION TppWorkerpList;
   LIST_ENTRY TppWorkerpList;
   PVOID WaitOnAddressHashTable[128];
   PVOID TelemetryCoverageHeader;
   ULONG CloudFileFlags;
   ULONG CloudFileDiagFlags;
   CHAR  PlaceholderCompatibilityMode;
   CHAR  PlaceholderCompatibilityModeReserved[7];
   PLEAP_SECOND_DATA LeapSecondData;
   union {
      ULONG LeapSecondFlags;
      struct {
         ULONG SixtySecondEnabled : 1;
         ULONG Reserved : 31;
      };
   };
   ULONG NtGlobalFlag2;
} PEB, *PPEB;
