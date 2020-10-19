function Test-Prime {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateRange(2, [UInt64]::MaxValue)]
    [UInt64]$Number
  )

  end {
    $Number -in (2, 5) ? $true : $(
      ($x = [Math]::Sqrt($Number)) -eq [Math]::Floor($x) ? $false : $(
        ($Number % 10) -in (1, 3, 7, 9) ? $(
          for ($i = 3; $i -lt $x; $i += 2) {
            if (($Number % $i) -eq 0) {
              Write-Verbose "Divisor is $i"
              return $false
            }
          }
          $true
        ) : $false
      )
    )
  }
}
