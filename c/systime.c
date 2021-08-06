#ifndef UNICODE
  #define UNICODE
#endif

#include <windows.h>
#include <stdio.h>

#pragma comment (lib, "ntdll.lib")

typedef SHORT CSHORT;

typedef struct _KSYSTEM_TIME {
   ULONG LowPart;
   LONG  High1Part;
   LONG  High2Part;
} KSYSTEM_TIME, *PKSYSTEM_TIME;

typedef struct _TIME_FIELDS {
   CSHORT Year;
   CSHORT Month;
   CSHORT Day;
   CSHORT Hour;
   CSHORT Minute;
   CSHORT Second;
   CSHORT Milliseconds;
   CSHORT DayOfWeek;
} TIME_FIELDS, *PTIME_FIELDS;

int wmain(void) {
  TIME_FIELDS tf = {0};
  KSYSTEM_TIME kst = *((KSYSTEM_TIME *)0x7FFE0014);
  RtlTimeToTimeFields((PLARGE_INTEGER)&kst, &tf);
  wprintf(L"%02hu/%02hu/%hu %02hu:%02hu:%02hu\n",
    tf.Month, tf.Day, tf.Year, tf.Hour, tf.Minute, tf.Second
  );

  return 0;
}
