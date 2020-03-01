import wintypes as nt

from enum import IntEnum
# ====================================================================================
PREFETCHER_INFORMATION_CLASS = IntEnum('PREFETCHER_INFORMATION_CLASS', (
   'PrefetcherRetrieveTrace',
   'PrefetcherSystemParameters',
   'PrefetcherBootPhase',
   'PrefetcherRetrieveBootLoaderTrace',
   'PrefetcherBootControl',
), start=1)

class PREFETCHER_INFORMATION(nt.CStruct):
   _fields_ = (
      ('Version',                     nt.ULONG),
      ('Magic',                       nt.ULONG), # kuhC
      ('_PrefetcherInformationClass', nt.ULONG),
      ('PrefetcherInformation',       nt.PVOID),
      ('PrefetcherInformationLengh',  nt.ULONG),
   )
   @property
   def PrefetcherInformationClass(self):
      return PREFETCHER_INFORMATION_CLASS(
         self._PrefetcherInformationClass
      ).name if self._PrefetcherInformationClass else None

SUPERFETCH_INFORMATION_CLASS = IntEnum('SUPERFETCH_INFORMATION_CLASS', (
   'SuperfetchRetrieveTrace',
   'SuperfetchSystemParameters',
   'SuperfetchLogEvent',
   'SuperfetchGenerateTrace',
   'SuperfetchPrefetch',
   'SuperfetchPfnQuery',
   'SuperfetchPfnSetPriority',
   'SuperfetchPrivSourceQuery',
   'SuperfetchSequenceNumberQuery',
   'SuperfetchScenarioPhase',
   'SuperfetchWorkerPriority',
   'SuperfetchScenarioQuery',
   'SuperfetchScenarioPrefetch',
   'SuperfetchRobustnessControl',
   'SuperfetchTimeControl',
   'SuperfetchMemoryListQuery',
   'SuperfetchMemoryRangesQuery',
   'SuperfetchTracingControl',
   'SuperfetchTrimWhileAgingControl',
   'SuperfetchRepurposedByPrefetch',
   'SuperfetchInformationMax',
), start=1)

class SUPERFETCH_INFORMATION(nt.CStruct):
   _fields_ = (
      ('Version',                     nt.ULONG),
      ('Magic',                       nt.ULONG), # kuhC
      ('_SuperfetchInformationClass', nt.ULONG),
      ('SuperfetchInformation',       nt.PVOID),
      ('SuperfetchInformationLength', nt.ULONG),
   )
   @property
   def InfoClass(self):
      return SUPERFETCH_INFORMATION_CLASS(
         self._SuperfetchInformationClass
      ).name if self._SuperfetchInformationClass else None
