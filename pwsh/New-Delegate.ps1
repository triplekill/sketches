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
    $mod = ($ps = Get-Process -Id $PID).Modules
    $ps.Dispose()
    $jmp = [Marshal]::ReadInt32($mod[0].BaseAddress, 0x3C) + [Marshal]::SizeOf([UInt32]0)
    $jmp = switch([BitConverter]::ToUInt16( # make sure the number is unsigned
      [BitConverter]::GetBytes([Marshal]::ReadInt32($mod[0].BaseAddress, $jmp)), 0
    )) { 0x14C {0x20, 0x78} 0x8664 {0x40, 0x88} default { throw } }
    $to_i = "ToInt$($jmp[0])"
    if (!($ib = $mod.Where{$_.ModuleName -match "^$Module"}.BaseAddress)) {
      throw [DllNotFoundException]::new("Cannot find $Module library.")
    }
    $tmp = $ib.$to_i()
    $va = [Marshal]::ReadInt32([IntPtr]([Marshal]::ReadInt32($ib, 0x3C) + $tmp + $jmp[1]))
    $ed = @{bs = 0x10; nf = 0x14; nn = 0x18; af = 0x1C; an = 0x20; ao = 0x24}
    $ed.Keys.ForEach{ # key fields of IMAGE_EXPORT_DIRECTORY
      $val = [Marshal]::ReadInt32($ib, $va + $ed.$_)
      Set-Variable -Name $_ -Value ($_.StartsWith('a') ? $tmp + $val : $val) -Scope Script
    }
    $funcs, $names = @{}, @{}
    (0..($nf - 1)).ForEach{
      $funcs[$bs + $_] = [IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($af + $_ * 4)))
    }
    (0..($nn - 1)).ForEach{
      $names[($bs + [Marshal]::ReadInt16([IntPtr]($ao + $_ * 2)))] = [Marshal]::PtrToStringAnsi(
        [IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($an + $_ * 4)))
      )
    }
    $exports = $funcs.Keys.ForEach{
      [PSCustomObject]@{
        Ordinal = $_
        Address = $funcs[$_]
        Name    = $names[$_]
      }
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
      $fnsig, $fnarg = $exports.Where{$_.Name -ceq $fname}.Address, $def.Pipeline.Extent.Text

      [Object[]]$fnarg = [String]::IsNullOrEmpty($fnarg) ? $fnret : (
        ($fnarg -replace '\[|\]' -split ',\s+?').ForEach{
          $_.StartsWith('_') ? (Get-Variable $_.Remove(0, 1) -ValueOnly) : $_
        } + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnarg)
      ).Invoke([Marshal], $fnsig)
    }

    Set-Variable -Name $Module -Value $funcs -Scope Script
  }
}
