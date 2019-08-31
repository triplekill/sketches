#requires -version 6
using namespace System.Runtime.InteropServices

if ([Marshal]::ReadInt32([IntPtr]0x7FFE026C) -ne 10) {
  Write-Warning "Windows 10 is strongly required."
  return
}

$key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
$eva = {param($high, $low)
  if ($high -and $low) {
    [DateTime]::FromFileTime([Int64]($high * 0x100000000) + $low)
  }
}

(Get-ChildItem "HKLM:\$key").ForEach{
  $val, $sid = @{}, $_.PSChildName
  ($cur = Get-ItemProperty $_.PSPath).PSObject.Properties.Where{
    $_.Name -match '^local.*time(high|low)$'
  }.ForEach{$val[$_.Name] = $_.Value}
  [PSCustomObject]@{
    UserName = Split-Path -Leaf $cur.ProfileImagePath
    LoadTimeProfile = &$eva `
      $val.LocalProfileLoadTimeHigh $val.LocalProfileLoadTimeLow
    UnloadTimeProfile = &$eva `
      $val.LocalProfileUnloadTimeHigh $val.LocalProfileUnloadTimeLow
    Sid = $sid
    Path = $cur.ProfileImagePath
  }
}
