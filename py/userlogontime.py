# -*- coding: utf-8 -*-
"""
from ctypes import byref, create_unicode_buffer, c_ulonglong, windll
from struct import pack, unpack
from winreg import HKEY_CURRENT_USER as HKCU, OpenKey, QueryInfoKey

FileTimeToLocalFileTime = windll.kernel32.FileTimeToLocalFileTime
FileTimeToSystemTime    = windll.kernel32.FileTimeToSystemTime
FormatMessage           = windll.kernel32.FormatMessageW
GetLastError            = windll.kernel32.GetLastError

def getlasterror():
   err, msg = GetLastError(), create_unicode_buffer(0x100)
   print('[Errno: 0x%X] %s' % (err, msg.value if FormatMessage(
      0x12FF, None, err, 1024, msg, len(msg), None
   ) else 'Unknown error has been occured.'))

def getlogontime():
   with OpenKey(HKCU, 'Volatile Environment') as rk:
      ts = c_ulonglong(QueryInfoKey(rk)[2])
   if not FileTimeToLocalFileTime(byref(ts), byref(ts)):
      getlasterror()
      return
   st = pack('HHHHHHHH', 1, 2, 3, 4, 5, 6, 7, 8)
   if not FileTimeToSystemTime(byref(ts), st):
      getlasterror()
      return
   st = ["{0:02}".format(x) for x in unpack('HHHHHHHH', st)]
   return "{0}/{1} {2}".format('/'.join(st[0:2]), st[3], ':'.join(st[4:7]))

if __name__ == '__main__':
   print(getlogontime())
"""
from datetime import datetime
from winreg   import HKEY_CURRENT_USER as HKCU, OpenKey, QueryInfoKey

if __name__ == '__main__':
   with OpenKey(HKCU, 'Volatile Environment')as rk:
      print(datetime.fromtimestamp(
         (QueryInfoKey(rk)[2] - 116444736 * 1e9) / 1e7
      ).strftime('%Y/%m/%d %H:%M:%S'))
