#requires -version 7
#$env:PAGER='less.exe'
#$env:LESSCHARSET='utf-8'
Set-PSReadlineOption -HistoryNoDuplicates
Set-Content function:prompt -Value @'
"`n`e[36;1m`u{250c}`u{2500}`e[46;97m[$(
   ($lastCmdInfo = Get-History -Count 1) ? $lastCmdInfo.Id + 1 : 1
)]`e[0m`e[36;1m`u{2500}[`e[32;23m$(
   $ExecutionContext.SessionState.Path.CurrentLocation
)`e[36;1m] `e[35;1m$(
  if (Test-Path .git\HEAD) {
    if (($$ = (
      Select-String '^ref:.*/(.*)$' .git\HEAD
    ).Matches.Groups[1].Value)) {"($($$))"}
  }
)`e[36;1m`n`u{2514}`e[33;1m$(
   "`u{3bb}" * ($NestedPromptLevel + 1)
)`e[0m`e[0 q`e[?12l "
'@

if ($IsLinux) {
  Register-EngineEvent PowerShell.Exiting -Action {
    find /tmp/ -type s -name '*.pwsh' -delete
  } | Out-Null
}

class fmt {
  [String]$hex
  [String]$dec
  [String]$oct
  [String]$bin
  [String]$chr
  [String]$time
  [String]$float
  [String]$double

  fmt ([Int64]$v) {
    $bytes = [BitConverter]::GetBytes($v)

    $this.hex = [Convert]::ToString($v, 16).PadLeft([IntPtr]::Size * 2, '0')
    $this.dec = $v
    $this.oct = [Convert]::ToString($v, 8).PadLeft(22, '0')
    $this.bin = ($$ = [Linq.Enumerable]::Reverse($bytes)).ForEach{
      [Convert]::ToString($_, 2).PadLeft(8, '0')
    }
    $this.chr = -join$$.ForEach{$_ -in (33..122) ? [Char]$_ : '.'}
    $this.time = try {
      $v -gt [UInt32]::MaxValue ? [DateTime]::FromFileTime($v)
                       : ([DateTime]'1.1.1970').AddSeconds($v).ToLocalTime()
    } catch { $_; 'n/a' }
    $this.float = 'low {0:G6} high {1:G6}' -f (
      [BitConverter]::ToSingle($bytes, 0)
    ), ([BitConverter]::ToSingle($bytes, 4))
    $this.double = '{0:G6}' -f [BitConverter]::Int64BitsToDouble($v)
  }
}
