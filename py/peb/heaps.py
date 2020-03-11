from wintypes import *
from struct   import pack, unpack
from sys      import argv, exit

class EnumProcessHeaps(object): # only addresses of heaps
   def __init__(self, pid=None):
      self._handle = OpenProcess(
         PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, False, pid
      ) if pid else GetCurrentProcess()
      peb_addr = None # getting PEB address
      try:
         peb_addr = self._get_peb_addr()
      except OSError:
         exit(1)
      peb = PEB() # fill PEB structure
      if not ReadProcessMemory(
         self._handle, peb_addr, byref(peb), peb.size, None
      ): # show reason of failure end exit
         GetWin32Error()
         exit(1)
      heaps = pack('P' * peb.NumberOfHeaps, *range(peb.NumberOfHeaps))
      if not ReadProcessMemory(
         self._handle, peb.ProcessHeaps, heaps, len(heaps), None
      ): # mission impossible :)
         GetWin32Error()
         exit(1)
      [print(hex(addr)) for addr in unpack('P' * peb.NumberOfHeaps, heaps)]
   def __del__(self):
      if self._handle:
         if not CloseHandle(self._handle):
            GetWin32Error()
   def _get_peb_addr(self):
      pbi = PROCESS_BASIC_INFORMATION()
      if (nts := NtQueryInformationProcess(
         self._handle, ProcessBasicInformation, byref(pbi), pbi.size, None
      )) != STATUS_SUCCESS:
         raise OSError(GetNtError(nts))
      return pbi.PebBaseAddress

"""
# usage example
if __name__ == '__main__':
   if len(argv) != 2:
      print('Index is out of range.')
      exit(1)
   if not (pid := argv[1]).isdigit():
      print('PID should be an integer.')
      exit(1)
   EnumProcessHeaps(int(pid))
"""
