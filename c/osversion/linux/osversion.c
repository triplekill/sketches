#include <stdio.h>
#include <sys/utsname.h>

int main(void) {
  struct utsname u = {0};
  int err = uname(&u);

  if (0 != err) {
    perror("uname");
    return err;
  }

  printf(
    "Name   : %s\nRelease: %s\nVesion : %s\n",
    u.sysname, u.release, u.version
  );

  return 0;
}
