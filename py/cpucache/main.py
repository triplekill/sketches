#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from platform import system

if __name__ == '__main__':
   os = system()
   if 'Linux' == os:
      from deps.linux import getcpucache
   elif 'Windows' == os:
      from deps.winnt import getcpucache
   print('\n'.join(getcpucache()))
