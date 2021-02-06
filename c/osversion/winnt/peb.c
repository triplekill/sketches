#include <intrin.h>
#include <stdio.h>

typedef unsigned  char byte;
typedef unsigned  long uint;
typedef unsigned short ushort;

int main(void) {
  byte *peb;
#ifdef _M_X64
  peb = (byte *)__readgsqword(0x60);
  printf("%lu.%lu.%hu\n",
    *(uint *)(peb + 0x118),
    *(uint *)(peb + 0x11C),
    *(ushort *)(peb + 0x120)
  );
#else
  peb = (byte *)__readfsdword(0x30);
  printf("%lu.%lu.%hu\n",
    *(uint *)(peb + 0x0A4),
    *(uint *)(peb + 0x0A8),
    *(ushort *)(peb + 0x0AC)
  );
#endif

  return 0;
}
