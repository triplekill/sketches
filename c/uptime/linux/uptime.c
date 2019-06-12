#include <stdio.h>
#include <sys/sysinfo.h>

void getuptime(long sec) {
  printf(
    "%ld.%.2ld:%.2ld:%.2ld\n",
    sec / 86400, (sec / 3600) % 24, (sec % 3600) / 60, sec % 60
  );
}

int main(void) {
  struct sysinfo si;

  if (0 != sysinfo(&si)) {
    perror("sysinfo");
    return 1;
  }
  getuptime(si.uptime);

  return 0;
}
