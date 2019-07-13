#requires -version 7
using namespace System.Windows.Media

Add-Type -AssemblyName WindowsBase

function Find-FibonacciNumber {
  [OutputType([Double])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateScript({$_ -ge 1})]
    [UInt16]$n
  )

  process {
    $m1, $m2 = [Matrix]::new(1,0,0,1,0,0), [Matrix]::new(1,1,1,0,0,0)
    for ($i = 1; $i -lt $n; $i++) { $m1 *= $m2 }
    $m1.M11
  }
}
