#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from datetime import timedelta
from platform import system
from struct   import pack, unpack
from sys      import exit

if __name__ == '__main__':
   os = system()
   if 'Linux' == os:
      from ctypes import CDLL
      libc = CDLL('libc.so.6')
      si = pack('l9LH2LI', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
      err = libc.sysinfo(si)
      if 0 != err:
         libc.perror('sysinfo')
         exit(err)
      si = unpack('l9LH2LI', si)
      print(timedelta(seconds=si[0]))
   elif 'Windows' == os:
      from ctypes import create_unicode_buffer, windll
      sti = pack('qqqLLQQ', 1, 2, 3, 4, 5, 6, 7)
      nts = windll.ntdll.NtQuerySystemInformation(3, sti, len(sti), None)
      if 0 != nts:
         msg = create_unicode_buffer(0x100)
         err = windll.ntdll.RtlNtStatusToDosError(nts)
         print('Unknown error has been occured.'
            if not windll.kernel32.FormatMessageW(
               0x12FF, None, err, 1024, msg, len(msg), None
            ) else msg.value
         )
         exit(err)
      sti = unpack('qqqLLQQ', sti)
      print(timedelta(seconds=int((sti[1] - sti[0]) // 1e7)))
