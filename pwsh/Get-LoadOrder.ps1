#requires -version 5
Set-Alias -Name loadord -Value Get-LoadOrder
function Get-LoadOrder {
  [CmdletBinding()]
  param([Parameter()][Switch]$AsTable)

  begin {
    $root = 'HKLM:\SYSTEM\CurrentControlSet'
    $type = 'Boot', 'System', 'Automatic' # launching types
    $group, $items = (Get-ItemProperty "$root\Control\ServiceGroupOrder"
     ).List, (Get-ItemProperty "$root\Services\*").Where{$_.Start -lt 3}
    $order = @{} # approximate launch order
    (Get-ItemProperty "$root\Control\GroupOrderList"
     ).PSObject.Properties.Where{$_.Name -notlike 'ps*'}.ForEach{
       $order[$_.Name] = @()
       for ($i = 0; $i -lt $_.Value.Length; $i += 3) {
         $order[$_.Name] += [BitConverter]::ToUInt16($_.Value[$i..($i + 3)], 0)
         $i++
       } # remove tags counter
       $order[$_.Name] = $order[$_.Name][1..($order[$_.Name].Length - 1)]
     }

    function private:Get-Objects([String]$Value) {
      process {
        $scope = $items.Where{$_.Start -eq $type.IndexOf($Value)}
        $parts = $scope | Group-Object -Property Group
        $parts = foreach ($i in $(foreach ($g in $group) {
          $parts.Where{$_.Name -eq $g}
        })) {
          if ($i.Count -gt 1) {
            $cast = $i.Group.Where{$_.Tag}
            $($(foreach ($o in $order[$i.Name]) {
              $i.Group.Where{$_.Tag -eq $o}
            }), $cast.Where{
              $_.Tag -notin $order[$i.Name]
            }, $i.Group.Where{!$_.Tag}).ForEach{$_}
          }
          else { $i.Group }
        }
        $parts += $scope.Where{$_.Group -notin $group}
        foreach ($p in $parts) {
          [PSCustomObject]@{
            StartType = $Value
            Group = $p.Group
            Tag = $p.Tag
            ServiceOrDevice = $p.PSChildName
            ImagePath = $p.ImagePath
          }
        }
      }
    } # Get-Objects
  }
  process {}
  end {
    switch ($AsTable) {
      $true  { $type.ForEach{Get-Objects $_} | Format-Table -AutoSize }
      $false { $type.ForEach{Get-Objects $_} }
    }
  }
}
