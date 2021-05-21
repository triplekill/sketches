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
    if (!($exp = $ExecutionContext.SessionState.PSVariable.Get("__$Module").Value)) {
      $mod = ($ps = Get-Process -Id $PID).Modules.Where{$_.ModuleName -match "^$Module"}.BaseAddress
      $ps.Dispose() && ($mod ? $($jmp = ( # checking that DLL is loaded, otherwise throw an exception
        $mov = [Marshal]::ReadInt32($mod, 0x3C)) + [Marshal]::SizeOf([UInt32]0) # e_lfanew
      ) : $(throw [DllNotFoundException]::new("It seems that $Module is not loaded.")))
      $jmp = switch ([BitConverter]::ToUInt16([BitConverter]::GetBytes([Marshal]::ReadInt16($mod, $jmp)), 0)) {
        0x014C { 0x20, 0x78, 0x7C } 0x8664 { 0x40, 0x88, 0x8C } default { throw [SystemException]::new() }
      } # getting Export Directory values and key fields of the IMAGE_EXPORT_DIRECTORY structure
      $tmp, $fun = $mod."ToInt$($jmp[0])"(), @{}
      $va, $sz = $jmp[1,2].ForEach{[Marshal]::ReadInt32($mod, $mov + $_)}
      ($ed = @{bs = 0x10; nf = 0x14; nn = 0x18; af = 0x1C; an = 0x20; ao = 0x24}).Keys.ForEach{
        $val = [Marshal]::ReadInt32($mod, $va + $ed.$_)
        Set-Variable -Name $_ -Value ($_.StartsWith('a') ? $tmp + $val : $val) -Scope Script
      } # well, it's time to get the export table itself
      function Assert-Forwarder([UInt32]$fa) { end { ($va -le $fa) -and ($fa -lt ($va + $sz))} }
      (0..($nf - 1)).ForEach{
        $fun[$bs + $_] = (Assert-Forwarder ($fa = [Marshal]::ReadInt32([IntPtr]($af + $_ * 4)))) ? @{
          Address = ''; Forward = [Marshal]::PtrToStringAnsi([IntPtr]($tmp + $fa))
        } : @{Address = [IntPtr]($tmp + $fa); Forward = ''}
      }
      Set-Variable -Name "__$Module" -Value ($exp = (0..($nn - 1)).ForEach{
        [PSCustomObject]@{
          Ordinal = ($ord = $bs + [Marshal]::ReadInt16([IntPtr]($ao + $_ * 2)))
          Address = $fun[$ord].Address
          Name = [Marshal]::PtrToStringAnsi([IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($an + $_ * 4))))
          Forward = $fun[$ord].Forward
        }
      }) -Option ReadOnly -Scope Global -Visibility Private
    }
  }
  # process {} # ignore this block
  end {
    $funcs = @{}
    for ($i, $m, $fn, $p = 0, ([Expression].Assembly.GetType(
        'System.Linq.Expressions.Compiler.DelegateHelpers'
      ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
      ), [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr])),
      $Signature.Ast.FindAll({$args[0].CommandElements}, $true).ToArray();
      $i -lt $p.Length; $i++
    ) { # everything is ready to create a set of delegates... let's do it!
      $fnret, $fname = ($def = $p[$i].CommandElements).Value
      $fnsig, $fnarg = $exp.Where{$_.Name -ceq $fname}.Address, $def.Pipeline.Extent.Text

      if (!$fnsig) { throw [InvalidOperationException]::new("Cannot find $fname signature. Are you correct?") }

      [Object[]]$fnarg = [String]::IsNullOrEmpty($fnarg) ? $fnret : (
        ($fnarg -replace '\[|\]' -split ',\s+').ForEach{
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
