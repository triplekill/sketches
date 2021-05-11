# -*- coding: utf-8 -*-
from ctypes import (
   POINTER, Structure, Union, addressof, byref, cast, create_string_buffer,
   c_byte, c_long, c_longlong, c_ulong, c_ulonglong, c_ushort, c_size_t,
   c_void_p, c_wchar_p, pointer, sizeof, windll
)

FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100
FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000
LANG_NEUTRAL                   = 0x00000000
SUBLANG_DEFAULT                = 0x00000001
PROCESS_QUERY_INFORMATION      = 0x00000400
TOKEN_QUERY                    = 0x00000008

BOOL = c_long
BYTE = c_byte
DWORD = ULONG = c_ulong
HANDLE = HLOCAL = LPCVOID = PSID = PVOID = va_list = c_void_p
KPRIORITY = LONG = NTSTATUS = c_long
LONGLONG = c_longlong
LPWSTR = PWSTR = c_wchar_p
SIZE_T = c_size_t
UINT_PTR = c_ulonglong if 8 == sizeof(c_void_p) else c_ulong
ULONGLONG = c_ulonglong
USHORT = c_ushort

SystemSessionProcessInformation = ULONG(53) # SYSTEM_INFORMATION_CLASS
TokenUser = ULONG(1) # TOKEN_INFORMATION_CLASS
TokenStatistics = ULONG(10) # TOKEN_INFORMATION_CLASS
STATUS_SUCCESS = NTSTATUS(0x00000000).value
STATUS_INFO_LENGTH_MISMATCH = NTSTATUS(0xC0000004).value

CloseHandle = windll.kernelbase.CloseHandle
CloseHandle.restype = BOOL
CloseHandle.argtype = HANDLE

FormatMessage = windll.kernelbase.FormatMessageW
FormatMessage.restype = DWORD
FormatMessage.argtypes = (DWORD, LPCVOID, DWORD, DWORD, HLOCAL, DWORD, va_list)

GetLastError = windll.kernelbase.GetLastError
GetLastError.restype = DWORD
GetLastError.argtype = None

LocalFree = windll.kernelbase.LocalFree
LocalFree.restype = HLOCAL
LocalFree.argtype = HLOCAL

LsaFreeReturnBuffer = windll.secur32.LsaFreeReturnBuffer
LsaFreeReturnBuffer.restype = NTSTATUS
LsaFreeReturnBuffer.argtype = PVOID

LsaGetLogonSessionData = windll.secur32.LsaGetLogonSessionData
LsaGetLogonSessionData.restype = NTSTATUS
LsaGetLogonSessionData.argtypes = (PVOID, PVOID)

NtQueryInformationToken = windll.ntdll.NtQueryInformationToken
NtQueryInformationToken.restype = NTSTATUS
NtQueryInformationToken.argtypes = (HANDLE, ULONG, PVOID, ULONG, POINTER(ULONG))
NtCurrentProcessToken = c_void_p(-4)

NtQuerySystemInformation = windll.ntdll.NtQuerySystemInformation
NtQuerySystemInformation.restype = NTSTATUS
NtQuerySystemInformation.argtypes = (ULONG, PVOID, ULONG, POINTER(ULONG))

OpenProcess = windll.kernelbase.OpenProcess
OpenProcess.restype = HANDLE
OpenProcess.argtypes = (DWORD, BOOL, DWORD)

OpenProcessToken = windll.kernelbase.OpenProcessToken
OpenProcessToken.restype = BOOL
OpenProcessToken.argtypes = (HANDLE, DWORD, POINTER(HANDLE))

RtlNtStatusToDosError = windll.ntdll.RtlNtStatusToDosError
RtlNtStatusToDosError.restype = ULONG
RtlNtStatusToDosError.argtype = NTSTATUS


def getlasterror(nts : NTSTATUS) -> None:
   def MAKELANGID(p, s):
      return (s << 10) | p
   msg = LPWSTR()
   if 0 != FormatMessage(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM, None,
      RtlNtStatusToDosError(nts) if 0 != nts else GetLastError(),
      MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), byref(msg), 0, None
   ):
      print(msg.value.strip())
      if LocalFree(msg):
         print('LocalFree fatal error.')
   else:
      print('Unknown error has been occured.')

class CStruct(Structure):
   @property
   def size(self):
      return sizeof(self)

class LUID(Structure):
   _fields_ = (
      ('LowPart', ULONG),
      ('HighPart', LONG),
   )

class _LARGE_INTEGER(Structure):
   _fields_ = (
      ('LowPart', ULONG),
      ('HighPart', LONG),
   )

class LARGE_INTEGER(Union):
   _fields_ = (
      ('u1', _LARGE_INTEGER),
      ('u2', _LARGE_INTEGER),
      ('QuadPart', LONGLONG),
   )

class TOKEN_STATISTICS(CStruct):
   _fields_ = (
      ('TokenId',            LUID),
      ('AuthenticationId',   LUID),
      ('ExpirationTime',     LARGE_INTEGER),
      ('TokenType',          ULONG), # TOKEN_TYPE
      ('ImpersonationLevel', ULONG), # SECURITY_IMPERSONATION_LEVEL
      ('DynamicCharged',     DWORD),
      ('DynamicAvailable',   DWORD),
      ('GroupCount',         DWORD),
      ('PrivilegeCount',     DWORD),
      ('ModifiedId',         LUID),
   )

class UNICODE_STRING(Structure):
   _fields_ = (
      ('Length',        USHORT),
      ('MaximumLength', USHORT),
      ('Buffer',        PWSTR),
   )
LSA_UNICODE_STRING = UNICODE_STRING

class SID_IDENTIFIER_AUTHORITY(Structure):
   _fields_ = (
      ('Value', BYTE * 6),
   )

class SID(Structure):
   _fields_ = (
      ('Revision',            BYTE),
      ('SubAuthorityCount',   BYTE),
      ('IdentifierAuthority', SID_IDENTIFIER_AUTHORITY),
      ('SubAuthority',        ULONG * 1),
   )

class SECURITY_LOGON_SESSION_DATA(Structure):
   _fields_ = (
      ('Size',                  ULONG),
      ('LogonId',               LUID),
      ('_UserName',             LSA_UNICODE_STRING),
      ('LogonDomain',           LSA_UNICODE_STRING),
      ('AuthenticationPackage', LSA_UNICODE_STRING),
      ('LogonType',             ULONG),
      ('Session',               ULONG),
      ('Sid',                   PSID),
      ('LogonTime',             LARGE_INTEGER),
   )
   @property
   def UserName(self):
      return '{0}\\{1}'.format(self.LogonDomain.Buffer, self._UserName.Buffer)

class SID_AND_ATTRIBUTES(Structure):
   _fields_ = (
      ('Sid', POINTER(SID)),
      ('Attributes', DWORD),
   )

class TOKEN_USER(CStruct):
   _fields_ = (
      ('User', SID_AND_ATTRIBUTES),
   )

class SYSTEM_SESSION_PROCESS_INFORMATION(CStruct):
   _fields_ = (
      ('SessionId', ULONG),
      ('SizeOfBuf', ULONG),
      ('Buffer',    PVOID),
   )

class SYSTEM_PROCESS_INFORMATION(Structure):
   _fields_ = (
      ('NextEntryOffset',              ULONG),
      ('NumberOfThreads',              ULONG),
      ('WorkingSetPrivateState',       LARGE_INTEGER),
      ('HardFaultCount',               ULONG),
      ('NumberOfThreadsHighWatermark', ULONG),
      ('CycleTime',                    ULONGLONG),
      ('CreateTime',                   LARGE_INTEGER),
      ('UserTime',                     LARGE_INTEGER),
      ('KernelTime',                   LARGE_INTEGER),
      ('ImageName',                    UNICODE_STRING),
      ('BasePriority',                 KPRIORITY),
      ('UniqueProcessId',              HANDLE),
      ('InheritedFromUniqueProcessId', HANDLE),
      ('HandleCount',                  ULONG),
      ('SessionId',                    ULONG),
      ('UniqueProcessKey',             UINT_PTR),
      ('PeakVirtualSize',              SIZE_T),
      ('VirtualSize',                  SIZE_T),
      ('PageFaultCount',               ULONG),
      ('PeakWorkingSetSize',           SIZE_T),
      ('WorkingSetSize',               SIZE_T),
      ('QuotaPeakPagedPoolUsage',      SIZE_T),
      ('QuotaPagedPoolUsage',          SIZE_T),
      ('QuotaPeakNonPagedPoolUsage',   SIZE_T),
      ('QuotaNonPagedPoolUsage',       SIZE_T),
      ('PagefileUsage',                SIZE_T),
      ('PeakPagefileUsage',            SIZE_T),
      ('PrivatePageCount',             SIZE_T),
      ('ReadOperationCount',           LARGE_INTEGER),
      ('WriteOperationCount',          LARGE_INTEGER),
      ('OtherOperationCount',          LARGE_INTEGER),
      ('ReadTransferCount',            LARGE_INTEGER),
      ('WriteTransferCount',           LARGE_INTEGER),
      ('OtherTransferCount',           LARGE_INTEGER),
   )

def getcurusrsession() -> tuple:
   ts = TOKEN_STATISTICS()
   sz = c_ulong(ts.size)
   if STATUS_SUCCESS != (nts := NtQueryInformationToken(
      NtCurrentProcessToken, TokenStatistics, byref(ts), sz, byref(sz)
   )):
      getlasterror(nts)
      return ('', -1)
   luid, data = pointer(ts.AuthenticationId), PVOID()
   if STATUS_SUCCESS != (nts := LsaGetLogonSessionData(luid, byref(data))):
      getlasterror(nts)
      return ('', -1)
   slsd = cast(data, POINTER(SECURITY_LOGON_SESSION_DATA)).contents
   res = (slsd.UserName, slsd.Session)
   if STATUS_SUCCESS != (nts := LsaFreeReturnBuffer(data)):
      getlasterror(nts)
   return res

def psessieve(num : ULONG) -> None:
   sspi, buf = SYSTEM_SESSION_PROCESS_INFORMATION(), create_string_buffer(0x1000)
   sspi.SessionId = num
   sspi.SizeOfBuf = len(buf)
   sspi.Buffer    = addressof(buf)

   ret = ULONG()
   if STATUS_INFO_LENGTH_MISMATCH != (nts := NtQuerySystemInformation(
      SystemSessionProcessInformation, byref(sspi), sspi.size, byref(ret)
   )):
      getlasterror(nts)
      return None
   buf = create_string_buffer(ret.value)
   sspi.SizeOfBuf = len(buf)
   sspi.Buffer    = addressof(buf)
   if STATUS_SUCCESS != (nts := NtQuerySystemInformation(
      SystemSessionProcessInformation, byref(sspi), sspi.size, byref(ret)
   )):
      getlasterror(nts)
      return None
   adr = addressof(buf)
   spi = cast(adr, POINTER(SYSTEM_PROCESS_INFORMATION))
   while (spi[0].NextEntryOffset):
      print('{0:4}: {1}'.format(spi[0].UniqueProcessId, spi[0].ImageName.Buffer))
      adr += spi[0].NextEntryOffset
      spi = cast(adr, POINTER(SYSTEM_PROCESS_INFORMATION))

if __name__ == '__main__':
   if -1 != (usr:= getcurusrsession())[-1]:
      psessieve(usr[-1])
