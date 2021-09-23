using namespace System.Runtime.InteropServices

$GetKernelbaseExports = {
  end {
    $jmp = ($mov = [Marshal]::ReadInt32(( # IMAGE_NT_HEADERS
      $mod = ($ps = Get-Process -Id $PID).Modules.Where{
        $_.ModuleName -match 'kernelbase'}.BaseAddress), 0x3C
      )
    ) + [Marshal]::SizeOf([UInt32]0)
    $ps.Dispose()

    $j = switch ([BitConverter]::ToUInt16( # IMAGE_FILE_HEADER->Machine
      [BitConverter]::GetBytes([Marshal]::ReadInt16($mod, $jmp)), 0)
    ) { # integer type, offsets of VA and size
      0x0014C { 0x20, 0x78, 0x7C }
      0x08664 { 0x40, 0x88, 0x8C }
      default { throw [SystemException]::new() }
    }

    $tmp,$fun = $mod."ToInt$($j[0])"(), @{}
    $va, $sz = $j[1..2].ForEach{[Marshal]::ReadInt32($mod, $mov + $_)}
    ($e=@{bs=0x10;nf=0x14;nn=0x18;af=0x1C;an=0x20;ao=0x24}).Keys.ForEach{
      $$ = [Marshal]::ReadInt32($mod, $va + $e.$_)
      Set-Variable -Name $_ -Value ($_.StartsWith('a') ? $tmp + $$ : $$) -Scope Script
    }

    function Assert-Forwarder([UInt32]$fa) {end{($va -le $fa) -and ($fa -lt ($va + $sz))}}
    (0..($nf - 1)).ForEach{
      $fun[$bs + $_] = (
        Assert-Forwarder ($fa = [Marshal]::ReadInt32([IntPtr]($af + $_ * 4)))
      ) ? @{Address = ''; Forward = [Marshal]::PtrToStringAnsi([IntPtr]($tmp + $fa))}
        : @{ Address = [IntPtr]($tmp + $fa); Forward = '' }
    }
    (0..($nn - 1)).ForEach{
      [PSCustomObject]@{
        Ordinal = ($ord = $bs + [Marshal]::ReadInt16([IntPtr]($ao + $_ * 2)))
        Address = $fun[$ord].Address
        Name = [Marshal]::PtrToStringAnsi(
          [IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($an + $_ * 4)))
        )
        ForwarderTo = $fun[$ord].Forward
      }
    }
  }
}
