# -*- coding: utf-8 -*-
from ctypes   import (
   POINTER, Structure, byref, cast, create_unicode_buffer, c_byte, c_long, c_longlong,
   c_ulong, c_ushort, c_void_p, c_wchar_p, sizeof, windll
)
from datetime import datetime
from enum     import IntEnum

SECURITY_LOGON_TYPE = IntEnum('SECURITY_LOGON_TYPE', 'UndefinedLogonType Interactive \
   Network Batch Service Proxy Unlock NetworkCleartext NewCredentials RemoteInteractive \
   CachedInteractive CachedRemoteInteractive CachedUnlock')

ConvertSidToStringSid     = windll.advapi32.ConvertSidToStringSidW
FormatMessage             = windll.kernel32.FormatMessageW
GetLastError              = windll.kernel32.GetLastError
LocalFree                 = windll.kernel32.LocalFree
LsaEnumerateLogonSessions = windll.secur32.LsaEnumerateLogonSessions
LsaFreeReturnBuffer       = windll.secur32.LsaFreeReturnBuffer
LsaGetLogonSessionData    = windll.secur32.LsaGetLogonSessionData
LsaNtStatusToWinError     = windll.advapi32.LsaNtStatusToWinError

class LUID(Structure):
   _fields_ = [
      ('LowPart',  c_ulong),
      ('HighPart', c_long),
   ]

class LSA_UNICODE_STRING(Structure):
   _fields_= [
      ('Length',        c_ushort),
      ('MaximumLength', c_ushort),
      ('Buffer',        c_wchar_p),
   ]

class SID_IDENTIFIER_AUTHORITY(Structure):
   _fields_ = [
      ('Value', c_byte * 6),
   ]

class SID(Structure):
   _fields_ = [
      ('Revision',            c_byte),
      ('SubAuthorityCount',   c_byte),
      ('IdentifierAuthority', SID_IDENTIFIER_AUTHORITY),
      ('SubAuthority',        c_ulong * 1),
   ]


"""
class LARGE_INTEGER_UNION(Union):
   _fields_ = [
      ('LowPart',  c_ulong),
      ('HighPart', c_long),
   ]

class LARGE_INTEGER(Structure):
   _fields_ = [
      ('u1',       LARGE_INTEGER_UNION),
      ('u2',       LARGE_INTEGER_UNION),
      ('QuadPart', c_longlong),
   ]

class LSA_LAST_INTER_LOGON_INFO(Structure):
   _fields_ = [
      ('LastSuccessfulLogon', LARGE_INTEGER),
      ('LastFailedLogon',     LARGE_INTEGER),
      ('FailedAttemptCountSinceLastSuccessfulLogon', c_ulong),
   ]
"""

class SECURITY_LOGON_SESSION_DATA(Structure):
   _fields_ = [
      ('Size',                  c_ulong),
      ('LogonId',               LUID),
      ('_UserName',             LSA_UNICODE_STRING),
      ('LogonDomain',           LSA_UNICODE_STRING),
      ('AuthenticationPackage', LSA_UNICODE_STRING),
      ('_LogonType',            c_ulong),
      ('Session',               c_ulong),
      ('_Sid',                  c_void_p), # PSID
      ('_LogonTime',            c_longlong), # LARGE_INTEGER
   ]
   @property
   def LogonType(self):
      return SECURITY_LOGON_TYPE(self._LogonType).name if self._LogonType else None
   @property
   def UserName(self):
      return '{0}\\{1}'.format(self.LogonDomain.Buffer, self._UserName.Buffer)
   @property
   def Sid(self):
      psid, ssid = cast(self._Sid, POINTER(SID)), c_wchar_p()
      sid = ssid.value if ConvertSidToStringSid(psid, byref(ssid)) else None
      if ssid.value:
         if LocalFree(ssid):
            getlasterror(0)
      return sid
   @property
   def LogofTime(self):
      return datetime.fromtimestamp(
         (self._LogonTime - 116444736 * 1e9) // 1e7
      ).strftime('%m/%d/%Y %H:%M:%S')
"""
      ('LogonServer',           LSA_UNICODE_STRING),
      ('DnsDomainName',         LSA_UNICODE_STRING),
      ('Upn',                   LSA_UNICODE_STRING),
      ('UserFlags',             c_ulong),
      ('LastLogonInfo',         LSA_LAST_INTER_LOGON_INFO),
      ('LogonScript',           LSA_UNICODE_STRING),
      ('ProfilePath',           LSA_UNICODE_STRING),
      ('HomeDirectory',         LSA_UNICODE_STRING),
      ('HomeDirectoryDrive',    LSA_UNICODE_STRING),
      ('LogofTime',             LARGE_INTEGER),
      ('KickOffTime',           LARGE_INTEGER),
      ('PasswordLastSet',       LARGE_INTEGER),
      ('PasswordCanCnahge',     LARGE_INTEGER),
      ('PasswordMustChange',    LARGE_INTEGER),
"""

def getlasterror(ntstatus):
   msg = create_unicode_buffer(0x100)
   err = LsaNtStatusToWinError(ntstatus) if 0 != ntstatus else GetLastError()
   print(msg.value if FormatMessage(
      0x12FF, None, err, 1024, msg, len(msg), None
   ) else 'Unknown error has been occured.')

def LSA_SUCCESS(ntstatus):
   if 0 != ntstatus:
      raise OSError(getlasterror(ntstatus))

if __name__ == '__main__':
   count, slist = c_ulong(), c_void_p()
   LSA_SUCCESS(LsaEnumerateLogonSessions(byref(count), byref(slist)))
   luid, data = c_void_p(slist.value), c_void_p()
   for i in range(count.value):
      if 0 != LsaGetLogonSessionData(luid, byref(data)):
         luid = c_void_p(luid.value + sizeof(LUID))
         continue # access denied, move next
      slsd = cast(data, POINTER(SECURITY_LOGON_SESSION_DATA)).contents
      print('Logon type   : %s' % slsd.LogonType)
      print('User name    : %s' % slsd.UserName)
      print('Auth package : %s' % slsd.AuthenticationPackage.Buffer)
      print('Session      : %u' % slsd.Session)
      print('Sid          : %s' % slsd.Sid)
      print('Logon time   : %s\n' % slsd.LogofTime)
      luid = c_void_p(luid.value + sizeof(LUID))
      ntstatus = LsaFreeReturnBuffer(data)
      if 0 != ntstatus: getlasterror(ntstatus)
   LSA_SUCCESS(LsaFreeReturnBuffer(slist))
