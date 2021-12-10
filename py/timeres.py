#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from platform import system
from sys      import exit

if __name__ == '__main__':
   os = system()
   if 'Linux' == os:
      from ctypes import CDLL
      from struct import pack, unpack

      libc = CDLL('libc.so.6')
      timespec = pack('ql', 1, 2)

      if 0 != (err := libc.clock_getres(5, timespec)):
         libc.perror('clock_getres')
         exit(err)
      print('Current timer resolution: %.3f ms' % (unpack('ql', timespec)[1] / 1e6))
   elif 'Windows' == os:
      from ctypes import byref, create_unicode_buffer, c_bool, c_ulong, windll

      tm, inc, dis = c_ulong(), c_ulong(), c_bool()
      if not windll.kernel32.GetSystemTimeAdjustment(byref(tm), byref(inc), byref(dis)):
         err, msg = windll.kernel32.GetLastError(), create_unicode_buffer(0x100)
         print('Unknown error has been occured.'
            if not windll.kernel32.FormatMessageW(
               0x12FF, None, err, 0x400, msg, len(msg), None
            ) else msg.value
         )
         exit(err)
      print('Current timer resolution: %.3f ms' % (tm.value / 1e4))
   else:
      print('Unsupported OS version.')
