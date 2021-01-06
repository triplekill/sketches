using namespace System.Text
using namespace System.Reflection
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices

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
    $kernel32 = @{}
    [Array]::Find(( # GetModuleHandle, GetProcAddress
      Add-Type -AssemblyName Microsoft.Win32.SystemEvents -PassThru
    ), [Predicate[Type]]{$args[0].Name -eq 'kernel32'}).GetMethods(
      [BindingFlags]'NonPublic, Static, Public'
    ).Where{$_.Name -cmatch '\AGet(P|M)'}.ForEach{$kernel32[$_.Name] = $_}

    if (($mod = $kernel32.GetModuleHandle.Invoke($null, @($Module))) -eq [IntPtr]::Zero) {
      throw [DllNotFoundException]::new("Cannot find $Module library.")
    }
  }
  process {}
  end {
    $funcs = @{}
    for ($i, $m, $fn, $p = 0, ([Expression].Assembly.GetType(
        'System.Linq.Expressions.Compiler.DelegateHelpers'
      ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
      ), [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr])),
      $Signature.Ast.FindAll({$args[0].CommandElements}, $true).ToArray();
      $i -lt $p.Length; $i++
    ) {
      $fnret, $fname = ($def = $p[$i].CommandElements).Value

      if (($fnsig = $kernel32.GetProcAddress.Invoke($null, @($mod, $fname))) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = [String]::IsNullOrEmpty($fnargs) ? $fnret : (
        ($fnargs -replace '\[|\]' -split ',\s+?').ForEach{
          $_.StartsWith('_') ? (Get-Variable $_.Remove(0, 1) -ValueOnly) : $_
        } + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }

    Set-Variable -Name $Module -Value $funcs -Scope Script -Force
  }
}

# Easisest way:
#   whoami /priv /fo csv | ConvertFrom-Csv
function Get-TokenPrivileges {
  [CmdletBinding()]param()

  begin {
    $ptr, $buf, $uint_ = [IntPtr], [Byte[]], [UInt32].MakeByRefType()

    New-Delegate -Module advapi32 -Signature {
      bool GetTokenInformation([_ptr, uint, _buf, uint, _uint_])
      bool LookupPrivilegeDisplayNameW([string, _buf, _buf, _uint_, _uint_])
      bool LookupPrivilegeNameW([string, _buf, _buf, _uint_])
    }
  }
  process {}
  end {
    try {
      $sz = 0
      if (!$advapi32.GetTokenInformation.Invoke([IntPtr]-4, 3, $null, 0, [ref]$sz) -and $sz -ne 0) {
        $buf = [Byte[]]::new($sz)
        if (!$advapi32.GetTokenInformation.Invoke([IntPtr]-4, 3, $buf, $sz, [ref]$sz)) {
          throw [InvalidOperationException]::new('Cannot get required token information.')
        }
      }
      # getting PrivilegeCount (first field of TOKEN_PRIVILEGES)
      $PrivilegeCount = [BitConverter]::ToUInt32($buf[0..3], 0)
      # other bytes of $buf are $Privileges (LUID_AND_ATTRIBUTES[$PrivilegeCount])
      $Privileges = $buf[4..$buf.Length] # sizeof(LUID_AND_ATTRIBUTES) = 0x0C
      [Array]::Resize([ref]$buf, 0xff)
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
                ('Disabled', 'Default Enabled')[$Attributes -band 1], 'Enabled'
              )[($Attributes -band 2) -eq 2]
            }
          }
        }
        $Privileges = $Privileges[12..$Privileges.Length]
      }
    }
    catch { $_ }
  }
}
