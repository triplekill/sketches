#requires -version 6
function ConvertFrom-Roman {
  <#
    .EXAMPLE
        ConvertFrom-Roman XLVII # 47
    .EXAMPLE
        'dlxxvii' | ConvertFrom-Roman # 577
    .EXAMPLE
        ('mmxx', 'cdxxix', 'di').ForEach{ConvertFrom-Roman $_} # 2020, 429, 501
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidatePattern('^(?=[MDCLXVI])M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$')]
    [ValidateNotNullOrEmpty()]
    [String]$Number
  )

  process {
    $map = @{I = 1; V = 5; X = 10; L = 50; C = 100; D = 500; M = 1000}
    for ($i, $a = 0, [Char[]]$Number; $i -lt $a.Length; $i++) {
      ${<}, ${>} = "$($a[$i])", "$($a[$i + 1])"
      $dec += [Int64]"$('+-'[$i + 1 -lt $a.Length -and $map[${<}] -lt $map[${>}]])$($map[${<}])"
    }
    $dec
  }
}
