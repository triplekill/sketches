#requires -version 6

Add-Member -InputObject ([String] # [String].ent('...')
) -MemberType ScriptMethod -Name ent -Value {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$String
  )

  process {
    (([Char[]]$String | Group-Object).ForEach{
      -($e = $_.Count / $String.Length) * [Math]::Log($e, 2)
    } | Measure-Object -Sum).Sum.ToString('f3')
  }
} -Force

######################################################################################

Add-Member -InputObject ([String] # [String].rev('...')
) -MemberType ScriptMethod -Name rev -Value {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$String
  )

  process {
    ($res = [Linq.Enumerable]::Reverse($String)).Dispose()
    -join$res
  }
}

######################################################################################

Add-Member -InputObject ([String] # [String].rot13('...')
) -MemberType ScriptMethod -Name rot13 -Value {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$String
  )

  process {
    $top, $low = (65..77 + 97..109), (78..90 + 110..122)
    -join ([Char[]]$String).ForEach{
      $c = [Int32]$_
      [Char]$(if ($c -in $top) { $c + 13 }
      elseif ($c -in $low) { $c - 13}
      else { $c })
    }
  }
} -Force
