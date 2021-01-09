#include <intrin.h>
#include <stdio.h>

typedef unsigned char  BYTE;
typedef unsigned long  ULONG;
typedef unsigned short USHORT;

typedef BYTE   *PBYTE;
typedef ULONG  *PULONG;
typedef USHORT *PUSHORT;

int main(void) {
  PBYTE peb = (PBYTE)__readgsqword(0x60);
  printf("%d.%d.%d\n",
    *(PULONG)(peb + 0x118),
    *(PULONG)(peb + 0x11c),
    *(PUSHORT)(peb + 0x120)
  );

  return 0;
}
