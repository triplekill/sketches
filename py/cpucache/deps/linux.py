# -*- coding: utf-8 -*-
__all__ = ['getcpucache']

from ctypes import CDLL

def getcpucache():
   libc = CDLL('libc.so.6')
   data = list(zip(
      ['L1', 'L1', 'L2', 'L3', 'L4'],
      [tuple(
         libc.sysconf(x) for x in range(i, i + 3)
      ) for i in range(185, 200, 3)]
   ))
   form = '{0[0]}: {1:5} KB, Assoc {0[1][1]:2}, LineSize {0[1][2]}'
   for i in data:
      if not i[1][0]:
         continue
      yield form.format(i, i[1][0] // 1024)
