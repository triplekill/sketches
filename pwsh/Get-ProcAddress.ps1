using namespace System.Runtime.InteropServices

function Get-ProcAddress {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Module,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Function
  )

  end {
    $mod = ($ps = Get-Process -Id $PID).Modules
    $ps.Dispose()
    # check main executable bitness
    $jmp = [Marshal]::ReadInt32($mod[0].BaseAddress, 0x3C) + [Marshal]::SizeOf([UInt32]0)
    $jmp = switch ([BitConverter]::ToUInt16( # make sure the number is unsigned
      [BitConverter]::GetBytes([Marshal]::ReadInt32($mod[0].BaseAddress, $jmp)), 0
    )) { 0x14C {0x20, 0x78} 0x8664 {0x40, 0x88} default { throw } }
    # helper converter
    $to_i = "ToInt$($jmp[0])"
    # locating reuired module
    if (!($ib = $mod.Where{$_.ModuleName -match "^$Module"}.BaseAddress)) {
      throw [DllNotFoundException]::new("Cannot find $Module library.")
    }
    $tmp = $ib.$to_i()
    $va = [Marshal]::ReadInt32([IntPtr]([Marshal]::ReadInt32($ib, 0x3C) + $tmp + $jmp[1]))
    $bs = [Marshal]::ReadInt32($ib, $va + 0x10) # ordinal base
    $nf = [Marshal]::ReadInt32($ib, $va + 0x14) # number of functions
    $nn = [Marshal]::ReadInt32($ib, $va + 0x18) # number of names
    $af = $tmp + [Marshal]::ReadInt32($ib, $va + 0x1C) # address of functions
    $an = $tmp + [Marshal]::ReadInt32($ib, $va + 0x20) # address of names
    $ao = $tmp + [Marshal]::ReadInt32($ib, $va + 0x24) # address of name ordinals
    $funcs, $names = @{}, @{}
    (0..($nf - 1)).ForEach{
      $funcs[$bs + $_] = [IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($af + $_ * 4)))
    }
    (0..($nn - 1)).ForEach{
      $names[($bs + [Marshal]::ReadInt16([IntPtr]($ao + $_ * 2)))] = [Marshal]::PtrToStringAnsi(
        [IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($an + $_ * 4)))
      )
    }
    $funcs.Keys.ForEach{
      if ($names[$_] -in $Function) {
        [PSCustomObject]@{
          Ordinal = $_
          Address = $funcs[$_].ToString('X16')
          Name    = $names[$_]
        }
      }
    }
  }
}
