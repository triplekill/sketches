#requires -version 6.1
using namespace System.Reflection
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices

$keys, $types = ($accel = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys, @{
  buf   = [Byte[]]
  ptr   = [IntPtr]
  ptr_  = [IntPtr].MakeByRefType()
  uint_ = [UInt32].MakeByRefType()
}
$types.Keys.ForEach{ if ($_ -notin $keys) { $accel::Add($_, $types.$_) } }

function New-Delegate {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Module,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({![String]::IsNullOrEmpty($_)})]
    [ScriptBlock]$Signature
  )

  begin {
    $kernel32, $funcs, $method = @{}, @{}, [Expression].Assembly.GetType(
      'System.Linq.Expressions.Compiler.DelegateHelpers'
    ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
    # GetDelegateForFunctionPointer<T>(IntPtr ptr)
    $fn = [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr]))
    [Array]::Find(( # GetModuleHandle and GetProcAddress
      Add-Type -AssemblyName Microsoft.Win32.SystemEvents -PassThru
    ), [Predicate[Type]]{$args[0].Name -eq 'kernel32'}
    ).GetMethods([BindingFlags]'NonPublic, Static, Public').Where{
      $_.Name -cmatch '\AGet(M|P)'
    }.ForEach{ $kernel32[$_.Name] = $_ }

    if (( # no reason to continue
      $mod = $kernel32.GetModuleHandle.Invoke($null, @($Module))
    ) -eq [IntPtr]::Zero) {
      throw [DllNotFoundException]::new('Can not find the library.')
    }
  }
  process {}
  end {
    $proto = $Signature.Ast.FindAll({$args[0].StringConstantType}, $true).ToArray()
    for ($i = 0; $i -lt $proto.Length; $i += 2) {
      $block = $proto[$i..($i + 1)] # return type and function name with parameters
      $fnret, $fnname = $block[0].Extent.Text, $block[1].Extent.Text

      if (( # function signature (address)
        $fnaddr = $kernel32.GetProcAddress.Invoke($null, @($mod, $fnname))
      ) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new('Can not find function signature.')
      }

      $fnargs = $block[1].Parent.CommandElements[-1].PipeLine.Extent.Text
      [Object[]]$fnargs = (( # unparameterized function or not
        ($fnargs -replace '\[|\]' -split ',\s+?') + $fnret
      ), $fnret)[[String]::IsNullOrEmpty($fnargs)]

      $funcs[$fnname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $method).Invoke($fnargs)
      ).Invoke([Marshal], $fnaddr)
    } # for
    $funcs
  }
}

# Easiest way:
#   whoami /priv /fo csv | ConvertFrom-Csv
function Get-TokenPrivileges {
  [CmdletBinding()]
  param()

  begin {
    $advapi32, $kernel32, $token, $sz = (New-Delegate advapi32 -Signature {
      bool GetTokenInformation([ptr, uint, buf, uint, uint_])
      bool LookupPrivilegeDisplayNameW([string, buf, buf, uint_, uint_])
      bool LookupPrivilegeNameW([string, buf, buf, uint_])
      bool OpenProcessToken([ptr, uint, ptr_])
    }), (New-Delegate kernel32 -Signature {
      bool CloseHandle([ptr])
    }), [IntPtr]::Zero, 0
  }
  process {}
  end {
    try {
      if (!$advapi32.OpenProcessToken.Invoke([IntPtr]-1, 0x08, [ref]$token)) {
        throw [InvalidOperationException]::new('Can not get token access.')
      }

      # TokenPrivileges = 0x03
      if (!$advapi32.GetTokenInformation.Invoke($token, 0x03, $null, 0, [ref]$sz) -and $sz -ne 0) {
        $buf = [Byte[]]::new($sz)
        if (!$advapi32.GetTokenInformation.Invoke($token, 0x03, $buf, $sz, [ref]$sz)) {
          throw [InvalidOperationException]::new('Can not get token information.')
        }
      }
      # getting PrivilegeCount (first field of TOKEN_PRIVILEGES)
      $PrivilegeCount = [BitConverter]::ToUInt32($buf[0..3], 0)
      # other bytes of $buf are Privileges (LUID_AND_ATTRIBUTES[$PrivilegeCount])
      $Privileges = $buf[4..$buf.Length] # sizeof(LUID_AND_ATTRIBUTES) = 0x0C
      [Array]::Resize([ref]$buf, 255)
      for ($i = 0; $i -lt $Privileges.Length; $i++) {
        # sizeof(LUID) = 0x08, Attributes takes 4 bytes (DWORD)
        $LUID, $Attributes = $Privileges[0..7], [BitConverter]::ToUInt32($Privileges[8..11], 0)
        $buf.Clear()
        $sz = $buf.Length
        if ($advapi32.LookupPrivilegeNameW.Invoke($null, $LUID, $buf, [ref]$sz)) {
          $name = $buf[0..($sz * 2 - 1)] # keep in mind that is Unicode data
          $buf.Clear()
          $sz = $buf.Length
          if ($advapi32.LookupPrivilegeDisplayNameW.Invoke($null, $name, $buf, [ref]$sz, [ref]$null)) {
            [PSCustomObject]@{
              Privilege = [Encoding]::Unicode.GetString($name)
              Description = [Encoding]::Unicode.GetString($buf[0..($sz * 2 - 1)])
              Attributes = (
                ('Disabled','Default Enabled')[$Attributes -band 1], 'Enabled'
              )[($Attributes -band 2) -eq 2]
            }
          }
        }
        $Privileges = $Privileges[12..$Privileges.Length]
      }
    }
    catch { $_ }
    finally {
      if ($token -ne [IntPtr]::Zero) {
        if (!$kernel32.CloseHandle.Invoke($token)) {
          Write-Verbose 'Can not release token handle.'
        }
      }
    } # try
  }
}
