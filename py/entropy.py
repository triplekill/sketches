#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from collections import Counter
from math        import log2
from sys         import argv, exit

def entropy(src):
   c, sz = Counter(src), float(len(src))
   print('%.3f' % -sum(entropy / sz * log2(
      entropy / sz
   ) for entropy in c.values()))

if __name__ == '__main__':
   if 2 != len(argv):
      print('Index is out of range.')
      exit(1)
   f, r = None, None
   try:
      f = open(argv[1], 'rb')
      r = f.read()
      entropy(r)
   except FileNotFoundError:
      entropy(argv[1])
   finally:
      f.close() if f else exit(0)
