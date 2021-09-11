function Get-TriggeredServices {
  [CmdletBinding()]param()

  end {
    (Get-ChildItem HKLM:\SYSTEM\CurrentControlSet\Services).Where{
      $_.GetSubKeyNames() -contains 'TriggerInfo'
    }.ForEach{
      $top = $_.OpenSubKey('TriggerInfo')
      Split-Path -Leaf $_.Name
      foreach ($sub in $top.GetSubKeyNames()) {
        $inf = $_.OpenSubKey("TriggerInfo\$($sub)")
        "`tGUID: {0}  Type: {1}" -f [Guid]::new($inf.GetValue('Guid')), $inf.GetValue('Type')
        $inf.Dispose()
      }
      $top.Dispose()
      $_.Dispose()
    }
  }
}
