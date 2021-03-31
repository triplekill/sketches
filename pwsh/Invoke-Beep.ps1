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

$buf, $ptr, $ptr_ = [Byte[]], [IntPtr], [IntPtr].MakeByRefType()

New-Delegate kernelbase {
  bool CloseHandle([_ptr])
  bool DeviceIoControl([_ptr, uint, _buf, uint, _ptr, uint, _buf, _ptr])
}

New-Delegate ntdll {
  void RtlInitUnicodeString([_buf, _buf])
  int  RtlNtStatusToDosError([int])
  int  NtCreateFile([_ptr_, int, _buf, _buf, _ptr, uint, uint, uint, uint, _ptr, uint])
}

$uni = [Byte[]]::new(($psz = [IntPtr]::Size) * 2) # UNICODE_STRING
$ntdll.RtlInitUnicodeString.Invoke($uni, [Text.Encoding]::Unicode.GetBytes('\Device\Beep'))

$isb = [Byte[]]::new($psz * 2) # IO_STATUS_BLOCK
try {
  $gch = [GCHandle]::Alloc($uni, [GCHandleType]::Pinned)
  [Byte[]]$obj = [BitConverter]::GetBytes($psz * 6) + (
    ,0 * (($psz -eq 8 ? 4 : 0) + $psz) # OBJECT_ATTRIBUTES initialization
  ) + [BitConverter]::GetBytes(
    $gch.AddrOfPinnedObject()."ToInt$($psz * 8)"()
  ) + (,0 * ($psz * 3))

  $hndl = [IntPtr]::Zero
  if (0 -ne ($nts = $ntdll.NtCreateFile.Invoke(
    [ref]$hndl, 0x80000000, $obj, $isb, [IntPtr]::Zero, 128, 1, 3, 0, [IntPtr]::Zero, 0
  ))) { throw [ComponentModel.Win32Exception]::new($ntdll.RtlNtStatusToDosError.Invoke($nts)) }

  [Byte[]]$beep = [BitConverter]::GetBytes(1000) + [BitConverter]::GetBytes(700)
  $ret = [Byte[]]::new([Marshal]::SizeOf([UInt32]0))
  [void]$kernelbase.DeviceIoControl.Invoke(
    $hndl, (1 -shl 16), $beep, $beep.Length, [IntPtr]::Zero, 0, $ret, [IntPtr]::Zero
  )
}
catch { Write-Host $_ }
finally {
  if ($hndl -and $hndl -ne [IntPtr]::Zero) {
    if (!$kernelbase.CloseHandle.Invoke($hndl)) { Write-Warning 'device has not been released.' }
  }
  if ($gch) { $gch.Free() }
}
