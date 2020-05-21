#include <windows.h>
#include <winternl.h>
#include <intrin.h>
#include <stdio.h>

#define API_SET_SCHEMA_ENTRY_FLAGS_SEALED 1
#define InitializeUnicodeString(p, l, b) {               \
   (p)->Length = ((USHORT)(l));                          \
   (p)->MaximumLength = ((USHORT)((l) + sizeof(WCHAR))); \
   (p)->Buffer = ((PWSTR)(b));                           \
};

typedef struct _API_SET_NAMESPACE {
   ULONG Version;
   ULONG Size;
   ULONG Flags;
   ULONG Count;
   ULONG EntryOffset;
   ULONG HashOffset;
   ULONG HashFactor;
} API_SET_NAMESPACE, *PAPI_SET_NAMESPACE;

typedef struct _API_SET_NAMESPACE_ENTRY {
   ULONG Flags;
   ULONG NameOffset;
   ULONG NameLength;
   ULONG HashedLength;
   ULONG ValueOffset;
   ULONG ValueCount;
} API_SET_NAMESPACE_ENTRY, *PAPI_SET_NAMESPACE_ENTRY;

typedef struct _API_SET_VALUE_ENTRY {
   ULONG Flags;
   ULONG NameOffset;
   ULONG NameLength;
   ULONG ValueOffset;
   ULONG ValueLength;
} API_SET_VALUE_ENTRY, *PAPI_SET_VALUE_ENTRY;

int main(void) {
  PAPI_SET_NAMESPACE pasn = NULL;
#ifdef _M_X64
  pasn = ((PPEB)__readgsqword(0x60))->Reserved9[0];
#else
  pasn = ((PPEB)__readfsdword(0x30))->Reserved9[0];
#endif

  ULONG_PTR movn = (ULONG_PTR)pasn;
  PAPI_SET_NAMESPACE_ENTRY pasne = (PAPI_SET_NAMESPACE_ENTRY)(pasn->EntryOffset + movn);
  UNICODE_STRING name, value;

  // library, sealed, target(s)
  for (ULONG i = 0; i < pasn->Count; i++) {
    InitializeUnicodeString(&name, pasne->NameLength, pasne->NameOffset + movn);
    printf("%58wZ.dll | %5s | ",
      &name, (pasne->Flags & API_SET_SCHEMA_ENTRY_FLAGS_SEALED) != 0 ? "true" : "false"
    );

    PAPI_SET_VALUE_ENTRY pasve = (PAPI_SET_VALUE_ENTRY)(pasne->ValueOffset + movn);
    for (ULONG j = 0; j < pasne->ValueCount; j++) {
      InitializeUnicodeString(&value, pasve->ValueLength, pasve->ValueOffset + movn);
      printf("%wZ", &value);
      if ((j + 1) != pasne->ValueCount) printf(", ");
      pasve++;
    }
    printf("\n");
    pasne++;
  }

  return 0;
}
