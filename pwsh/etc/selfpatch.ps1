function test {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$String,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNull()]
    [Type]$Type
  )

  begin {
    $String
  }
  process {}
  end {
    $Type
  }
}

test 'dynamic message' ([int])

$blocks = (Get-Content function:test).Ast.Body | Select-Object *Block
Set-Content -Path function:test -Value ("  $($blocks.ParamBlock)`n`n" + @"
  begin {
    'patched!'
  }
"@ + "`n  $($blocks.ProcessBlock)`n" + @"
  end {
    [void]
  }
"@)

test 'dynamic message' ([int])
