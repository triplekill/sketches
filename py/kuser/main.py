from ctypes import POINTER, cast, c_void_p
from kuser  import KUSER_SHARED_DATA

if __name__ == '__main__':
   kuser = cast(c_void_p(0x7FFE0000), POINTER(KUSER_SHARED_DATA)).contents
   print('System root    : {0}'.format(kuser.NtSystemRoot))
   print('System version : {0}.{1}.{2}'.format(
      kuser.NtMajorVersion, kuser.NtMinorVersion, kuser.NtBuildNumber
   ))
   print('Product type   : {0}'.format(kuser.NtProductType))
   bitness = kuser.NativeProcessorArchitecture
   print('OS bitness     : {0}'.format(
      'x64' if bitness == 9 else 'x86' if bitness == 0 else 'Unknown'
   ))
   print('Processors     : {0}'.format(kuser.ActiveProcessorCount))
