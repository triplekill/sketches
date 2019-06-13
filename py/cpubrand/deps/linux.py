# -*- coding: utf-8 -*-
__all__ = ['getcpubrandstring']

def getcpubrandstring():
   from re import compile
   with open('/proc/cpuinfo', 'r') as f:
      res = ''.join(filter( # looking for among unique strings
         lambda s: compile('(?i:model name)').match(s), set(f.readlines())
      )).split(':')[1].strip()
   return res
