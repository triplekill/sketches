#requires -version 6.1
using namespace System.Reflection
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices

$keys, $types = ($accel = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys, @{
  buf   = [Byte[]]
  ptr   = [IntPtr]
  int_  = [Int32].MakeByRefType()
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
    $kernel32, $method = @{}, [Expression].Assembly.GetType(
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

    if ((
      $mod = $kernel32.GetModuleHandle.Invoke($null, @($Module))
    ) -eq [IntPtr]::Zero) {
      throw [DllNotFoundException]::new('Can not find the library.')
    }
  }
  process {}
  end {
    $funcs = @{}
    $proto = $Signature.Ast.FindAll({$args[0].StringConstantType}, $true).ToArray()

    for ($i = 0; $i -lt $proto.Length; $i += 2) {
      $block = $proto[$i..($i + 1)] # return type and function name with parameters
      if (!(($returntype = $block[0].Extent.Text) -as [Type])) {
        throw [InvalidCastException]::new('Unknown data type.')
      }
      $fnname = $block[1].Extent.Text

      if (( # function signature (address)
        $fnaddr = $kernel32.GetProcAddress.Invoke($null, @($mod, $fnname))
      ) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new('Can not find function signature.')
      }

      $fnargs = $block[1].Parent.CommandElements[-1].Pipeline.Extent.Text
      [Object[]]$fnargs = (( # unparameterized function or not
        ($fnargs -replace'\[|\]' -split ',\s+?') + $returntype
      ), $returntype)[[String]::IsNullOrEmpty($fnargs)]

      $funcs[$fnname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $method).Invoke($fnargs)
      ).Invoke([Marshal], $fnaddr)
    }
    $funcs
  }
}

<#
# Usage example

$ntdll = New-Delegate ntdll -Signature {
  int NtQueryTimerResolution([uint_, uint_, uint_])
  int RtlNtStatusToDosError([int])
}

$mx, $mn, $cr = [UInt32[]](,0 * 3)
if (($nts = $ntdll.NtQueryTimerResolution.Invoke([ref]$mx, [ref]$mn, [ref]$cr)) -ne 0) {
  [ComponentModel.Win32Exception]::new($ntdll.RtlNtStatusToDosError.Invoke($nts)).Message
  break
}
($mx, $mn, $cr).ForEach{ '{0:F3} ms' -f ($_ / 10000) }
#>
