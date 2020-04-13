#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <iostream>
#include <iomanip>
#include <string>
#include <cwchar>
#include <vector>
#include <memory>
#include <locale>

typedef LONG KPRIORITY;
typedef LONG NTSTATUS;

#define ProcessBasicInformation 0
#define NT_SUCCESS(Status) ((static_cast<NTSTATUS>(Status)) >= 0L)
#define AddrToFunc(T) ( \
  reinterpret_cast<T>( \
    GetProcAddress(GetModuleHandle(L"ntdll.dll"), (&((#T)[1]))) \
  ) \
)

/*
typedef struct _LIST_ENTRY {
   struct _LIST_ENTRY *Flink;
   struct _LIST_ENTRY *Blink;
} LIST_ENTRY, *PLIST_ENTRY;
*/

typedef struct _UNICODE_STRING {
   USHORT Length;
   USHORT MaximumLength;
   PWSTR  Buffer;
} UNICODE_STRING, *PUNICODE_STRING;

typedef struct _PEB_LDR_DATA {
   ULONG Length;
   BOOLEAN Initialized;
   HANDLE SsHandle;
   LIST_ENTRY InLoadOrderModuleList;
   LIST_ENTRY InMemoryOrderModuleList;
   LIST_ENTRY InInitializationOrderModuleList;
   PVOID EntryInProgress;
   BOOLEAN ShutdownInProgress;
   HANDLE ShutdownThreadId;
} PEB_LDR_DATA, *PPEB_LDR_DATA;

typedef struct _LDR_SERVICE_TAG_RECORD {
   struct _LDR_SERVICE_TAG_RECORD *Next;
   ULONG ServiceTag;
} LDR_SERVICE_TAG_RECORD, *PLDR_SERVICE_TAG_RECORD;

typedef struct _LDRP_CSLIST {
   PSINGLE_LIST_ENTRY Tail;
} LDRP_CSLIST, *PLDRP_CSLIST;

typedef enum _LDR_DDAG_STATE {
   LdrModulesMerged = -5,
   LdrModulesInitError = -4,
   LdrModulesSnapError = -3,
   LdrModulesUnloaded = -2,
   LdrModulesUnloading = -1,
   LdrModulesPlaceHolder = 0,
   LdrModulesMapping = 1,
   LdrModulesMapped = 2,
   LdrModulesWaitingForDependencies = 3,
   LdrModulesSnapping = 4,
   LdrModulesSnapped = 5,
   LdrModulesCondensed = 6,
   LdrModulesReadyToInit = 7,
   LdrModulesInitializing = 8,
   LdrModulesReadyToRun = 9
} LDR_DDAG_STATE;

/*
typedef struct _SINGLE_LIST_ENTRY {
   struct _SINGLE_LIST_ENTRY *Next;
} SINGLE_LIST_ENTRY, *PSINGLE_LIST_ENTRY;
*/

typedef struct _LDR_DDAG_NODE {
   LIST_ENTRY Modules;
   PLDR_SERVICE_TAG_RECORD ServiceTagList;
   ULONG LoadCount;
   ULONG LoadWhileUnloadingCount;
   ULONG LowestLink;
   LDRP_CSLIST Dependencies;
   LDRP_CSLIST IncomingDependencies;
   LDR_DDAG_STATE State;
   SINGLE_LIST_ENTRY CondenseLink;
   ULONG PreorderNumber;
} LDR_DDAG_NODE, *PLDR_DDAG_NODE;

typedef struct _RTL_BALANCED_NODE {
   union {
      struct _RTL_BALANCED_NODE *Children[2];
      struct {
         struct _RTL_BALANCED_NODE *Left;
         struct _RTL_BALANCED_NODE *Right;
      };
   };
   union {
      UCHAR Red : 1;
      UCHAR Balance : 2;
      ULONG_PTR ParentValue;
   };
} RTL_BALANCED_NODE, *PRTL_BALANCED_NODE;

typedef enum _LDR_DLL_LOAD_REASON {
   LoadReasonStaticDependency,
   LoadReasonStaticForwarderDependency,
   LoadReasonDynamicForwarderDependency,
   LoadReasonDelayloadDependency,
   LoadReasonDynamicLoad,
   LoadReasonAsImageLoad,
   LoadReasonAsDataLoad,
   LoadReasonEnclavePrimary,
   LoadReasonEnclaveDependency,
   LoadReasonUnknown = -1
} LDR_DLL_LOAD_REASON, *PLDR_DLL_LOAD_REASON;

typedef struct _LDR_DATA_TABLE_ENTRY {
   LIST_ENTRY InLoadOrderLinks;
   LIST_ENTRY InMemoryOrderLinks;
   LIST_ENTRY InInitializationOrderLinks;
   PVOID DllBase;
   PVOID EntryPoint;
   ULONG SizeOfImage;
   UNICODE_STRING FullDllName;
   UNICODE_STRING BaseDllName;
   union {
      UCHAR FlagGroup[4];
      ULONG Flags;
      struct {
         ULONG PackagedBinary : 1;
         ULONG MarkedForRemoval : 1;
         ULONG ImageDll : 1;
         ULONG LoadNotificationsSent : 1;
         ULONG TelemetryEntryProcessed : 1;
         ULONG ProcessStaticImport : 1;
         ULONG InLegacyLists : 1;
         ULONG InIndexes : 1;
         ULONG ShimDll : 1;
         ULONG InExceptionTable : 1;
         ULONG ReservedFlags1 : 2;
         ULONG LoadInProgress : 1;
         ULONG LoadConfigProcessed : 1;
         ULONG EntryProcessed : 1;
         ULONG ProtectDelayLoad : 1;
         ULONG ReservedFlags3 : 2;
         ULONG DontCallForThreads : 1;
         ULONG ProcessAttachCalled : 1;
         ULONG ProcessAttachFailed : 1;
         ULONG CorDeferredValidate : 1;
         ULONG CorImage : 1;
         ULONG DontRelocate : 1;
         ULONG CorILOnly : 1;
         ULONG ChpeImage : 1;
         ULONG ReservedFlags5 : 2;
         ULONG Redirected : 1;
         ULONG ReservedFlags6 : 2;
         ULONG CompatDatabaseProcessed : 1;
      } DUMMYSTRUCTNAME;
   } DUMMYUNIONNAME;
   USHORT ObsoleteLoadCount;
   USHORT TlsIndex;
   LIST_ENTRY HashLinks;
   ULONG TimeDateStamp;
   struct _ACTIVATION_CONTEXT *EntryPointActivationContext;
   PVOID Lock;
   PLDR_DDAG_NODE DdagNode;
   LIST_ENTRY NodeModuleLink;
   struct _LDRP_LOAD_CONTEXT *LoadContext;
   PVOID ParentDllBase;
   PVOID SwitchBackContext;
   RTL_BALANCED_NODE BaseAddressIndexNode;
   RTL_BALANCED_NODE MappingInfoIndexNode;
   ULONG_PTR OriginalBase;
   LARGE_INTEGER LoadTime;
   ULONG BaseNameHashValue;
   LDR_DLL_LOAD_REASON LoadReason;
   ULONG ImplicitPathOptions;
   ULONG ReferenceCount;
   ULONG DependentLoadFlags;
   UCHAR SigningLevel;
} LDR_DATA_TABLE_ENTRY, *PLDR_DATA_TABLE_ENTRY;

typedef struct _PROCESS_BASIC_INFORMATION {
   NTSTATUS ExitStatus;
   PVOID PebBaseAddress; // PPEB
   ULONG_PTR AffinityMask;
   KPRIORITY BasePriority;
   HANDLE UniqueProcessId;
   HANDLE InheritedFromUniqueProcessId;
} PROCESS_BASIC_INFORMATION, *PPROCESS_BASIC_INFORMATION;

typedef NTSTATUS (__stdcall *pNtQueryInformationProcess)(HANDLE, ULONG, PVOID, ULONG, PULONG);
typedef ULONG    (__stdcall *pRtlNtStatusToDosError)(NTSTATUS);

pNtQueryInformationProcess NtQueryInformationProcess;
pRtlNtStatusToDosError RtlNtStatusToDosError;

#ifdef _M_X64
  #define Ldr 0x18
#else
  #define Ldr 0x0c
#endif

BOOLEAN LocateSignatures(void) {
  NtQueryInformationProcess = AddrToFunc(pNtQueryInformationProcess);
  if (nullptr == NtQueryInformationProcess) return FALSE;

  RtlNtStatusToDosError = AddrToFunc(pRtlNtStatusToDosError);
  if (nullptr == RtlNtStatusToDosError) return FALSE;

  return TRUE;
}

int wmain(int argc, wchar_t **argv) {
  using namespace std;

  locale::global(locale(""));
  auto PrintErrMessage = [](NTSTATUS nts) {
    HLOCAL loc{};
    DWORD size = FormatMessage(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
      nullptr, 0L != nts ? RtlNtStatusToDosError(nts) : GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&loc), 0, nullptr
    );

    if (!size)
      wcout << L"[?] Unknown error has been occured." << endl;
    else {
      wstring msg(reinterpret_cast<LPWSTR>(loc));
      wcout << L"[!] " << msg.substr(0, size - sizeof(WCHAR)) << endl;
    }

    if (nullptr != LocalFree(loc))
      wcout << L"LocalFree (" << GetLastError() << L") fatal error." << endl;
  };

  if (!LocateSignatures()) {
    PrintErrMessage(0L);
    return 1;
  }

  if (2 != argc) {
    wstring app(argv[0]);
    wcout << L"Usage: " << app.substr(
      app.find_last_of(L"\\") + 1, app.length()
    ) << L" <PID>" << endl;
    return 1;
  }

  ULONG pid = wcstoul(argv[1], 0, 0);
  if (ERANGE == errno) {
    wcout << L"[!] Invalid PID diapason." << endl;
    return 1;
  }

  auto ps = shared_ptr<HANDLE>(new HANDLE(OpenProcess(
    PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, FALSE, pid
  )), [&PrintErrMessage](HANDLE *instance) {
    if (*instance) {
      if (!CloseHandle(*instance)) PrintErrMessage(0L);
      else wcout << L"[*] the process has been successfully closed" << endl;
    }
  });

  if (!*ps) {
    PrintErrMessage(0L);
    return 1;
  }
  wcout << L"[*] the process (" << pid << L") is successfully opened" << endl;

  PROCESS_BASIC_INFORMATION pbi = {0};
  NTSTATUS nts = NtQueryInformationProcess(
    *ps, ProcessBasicInformation, &pbi, sizeof(pbi), nullptr
  );
  if (!NT_SUCCESS(nts)) {
    PrintErrMessage(nts);
    return 1;
  }
  wcout << L"[*] PEB located at " << pbi.PebBaseAddress << endl;

  PPEB_LDR_DATA pldr = nullptr;
  if (!ReadProcessMemory(
    *ps, static_cast<PCHAR>(pbi.PebBaseAddress) + Ldr, &pldr, sizeof(PVOID), nullptr
  )) {
    PrintErrMessage(0L);
    return 1;
  }

  PLIST_ENTRY cur = &pldr->InLoadOrderModuleList;
  PLIST_ENTRY end = &pldr->InLoadOrderModuleList;
  while (1) {
    if (!ReadProcessMemory(*ps, cur, &cur, sizeof(PVOID), nullptr)) {
      PrintErrMessage(0L);
      break;
    }

    LDR_DATA_TABLE_ENTRY ldte = {0};
    if (!ReadProcessMemory(
      *ps, &cur->Flink, &ldte, sizeof(LDR_DATA_TABLE_ENTRY), nullptr
    )) {
      PrintErrMessage(0L);
      break;
    }

    if (nullptr == ldte.DllBase) break;

    vector<WCHAR> name(ldte.FullDllName.Length);
    if (!ReadProcessMemory(
      *ps, static_cast<LPCWSTR>(ldte.FullDllName.Buffer),
      &name[0], ldte.FullDllName.Length, nullptr
    )) {
      PrintErrMessage(0L);
      break;
    }

    wcout << ldte.DllBase << L" "
          << (!( // check base
            reinterpret_cast<ULONG_PTR>(ldte.DllBase) - ldte.OriginalBase
          ) ? L"-*" : L"*-") << L" "
          << ldte.EntryPoint << L" "
          // << ldte.LoadTime.QuadPart << L""
          << right << setw(16) << ldte.SizeOfImage << L" "
          << &name[0] << endl;

    if (cur == end) break;
  }

  return 0;
}
