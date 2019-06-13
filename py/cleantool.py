#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from os.path import abspath, dirname, join
from os      import walk
from shutil  import rmtree

# just removing cache in subfolders
if __name__ == '__main__':
   for root, dirs, _ in walk(dirname(abspath(__file__))):
      if '__pycache__' in dirs:
         rmtree(join(root, '__pycache__'), ignore_errors=True)
