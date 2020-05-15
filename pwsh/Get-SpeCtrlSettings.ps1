using namespace System.Linq
using namespace System.Reflection
using namespace System.ComponentModel
using namespace System.Linq.Expressions
using namespace System.Collections.Specialized
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
      [BindingFlags]'NonPublic, Public, Static'
    ).Where{$_.Name -cmatch '\AGet(P|M)'}.ForEach{$kernel32[$_.Name] = $_}

    if (($mod = $kernel32.GetModuleHandle.Invoke($null, @($Module))
    ) -eq [IntPtr]::Zero) {
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

      if (($fnsig = $kernel32.GetProcAddress.Invoke($null, @($mod, $fname))
      ) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = [String]::IsNullOrEmpty($fnargs) ? $fnret : (
        ($fnargs -replace '\[|\]' -split ',\s+?').ForEach{
          $_.StartsWith('$') ? (Get-Variable $_.Remove(0, 1) -ValueOnly) : $_
        } + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }
    Set-Variable -Name $Module -Value $funcs -Scope Script -Force
  }
}

function Get-BitData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Object]$Value,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({![String]::IsNullOrEmpty($_)})]
    [ScriptBlock]$Bits
  )

  end {
    $vtor = [BitVector32]::new($Value)
    [PSCustomObject](ConvertFrom-StringData (
      ($Bits.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
        $fname, $fbits = $_.CommandElements[0, 2]
        $mov = !$mov ? [BitVector32]::CreateSection($fbits.Value)
                     : [BitVector32]::CreateSection($fbits.Value, $mov)
        '{0} = {1}' -f $fname.Value, $vtor[$mov]
      }) | Out-String)
    )
  }
}


function Get-SpeCtrlSettings {
  [CmdletBinding()]param()

  begin {
    $buf, $ret = ,[Byte[]] * 2
    New-Delegate ntdll {
      int NtQuerySystemInformation([int, $buf, int, $ret])
      int RtlNtStatusToDosError([int])
    }

    $buf = [Byte[]](,0 * 4) # [Byte[]]::new([Marshal]::SizeOf([UInt32]0))
    # SystemKernelVaShadowInformation = 0n196
    if (($nts = $ntdll.NtQuerySystemInformation.Invoke(196, $buf, $buf.Length, $null)) -ne 0) {
      throw [Win32Exception]::new($ntdll.RtlNtStatusToDosError.Invoke($nts)).Message
    }
    $ks = Get-BitData -Value ([BitConverter]::ToUInt32($buf, 0)) -Bits {
       KvaShadowEnabled                 : 1
       KvaShadowUserGlobal              : 1
       KvaShadowPcid                    : 1
       KvaShadowInvpcid                 : 1
       KvaShadowRequired                : 1
       KvaShadowRequiredAvailable       : 1
       Reserved                         : 26
    }

    $buf.Clear() # using same buffer, simply clear it
    # SystemSpecualtionControlInformation = 0n201
    if (($nts = $ntdll.NtQuerySystemInformation.Invoke(201, $buf, $buf.Length, $null)) -ne 0) {
      throw [Win32Exception]::new($ntdll.RtlNtStatusToDosError.Invoke($nts)).Message
    }
    $sc = Get-BitData -Value ([BitConverter]::ToUInt32($buf, 0)) -Bits {
       BpbEnabled                               : 1
       BpbDisabledSystemPolicy                  : 1
       BpbDisabledNoHardwareSupport             : 1
       SpecCtrlEnumerated                       : 1
       SpecCmdEnumerated                        : 1
       IbrsPresent                              : 1
       StibpPresent                             : 1
       SmepPresent                              : 1
       SpeculativeStoreBypassDisableAvailable   : 1
       SpeculativeStoreBypassDisableSupported   : 1
       SpeculativeStoreBypassDisabledSystemWide : 1
       SpeculativeStoreBypassDisabledKernel     : 1
       SpeculativeStoreBypassDisableRequired    : 1
       BpbDisabledKernelToUser                  : 1
       SpecCtrlRetpolineEnabled                 : 1
       SpecCtrlImportOptimizationEnabled        : 1
       EnhancedIbrs                             : 1
       HvL1tfStatusAvailable                    : 1
       HvL1tfProcessorNotAffected               : 1
       HvL1tfMigitationEnabled                  : 1
       HvL1tfMigitationNotEnabled_Hardware      : 1
       HvL1tfMigitationNotEnabled_LoadOption    : 1
       HvL1tfMigitationNotEnabled_CoreScheduler : 1
       EnhancedIbrsReported                     : 1
       MdsHardwareProtected                     : 1
       MbClearEnabled                           : 1
       MbClearReported                          : 1
       TsxCtrlStatus                            : 2
       TsxCtrlReported                          : 1
       TaaHardwareImmune                        : 1
       Reserved                                 : 1
    }
  }
  process {}
  end {
    # example of data parsing
    'Hardware kernel VA shadowing available : {0}' -f $ks.KvaShadowRequiredAvailable
    if ($ks.KvaShadowRequiredAvailable -ne 0) {
      'Hardware requires kernel VA shadowing  : {0}' -f $ks.KvaShadowRequired
    }
    # and so on
  }
}
