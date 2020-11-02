function Protect-PSCode {
  <#
    .SYNOPSIS
        A concept of pwsh script obfuscator.
    .NOTES
        This technique shows good result on the small files but not on middle or
        huge. Do not try it in production.
  #>
  [CmdletBinding(DefaultParameterSetName='Path')]
  param(
    [Parameter(Mandatory, ParameterSetName='Path', Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [String]$Path,

    [Parameter(Mandatory, ParameterSetName='String', Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$String,

    [Parameter()]
    [String]$OutFile = "$pwd\$(-join('a'..'z' + 'A'..'Z' | Get-Random -Count 13)).ps1"
  )

  end {
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
      $String = Get-Content -Path $Path -Raw
    }

    $bit = @{ # reduced version
      0 = "`$()-!{}", "!{}+!{}", "!{}-!{}"
      1 = "!!{}+!{}", "!!{}-!{}"
    }

    $x = "`$`$=(''" + (-join [Text.Encoding]::ASCII.GetBytes($String).ForEach{
      ([Convert]::ToString($_, 2).PadLeft(8, '0') -split '').Where{$_}.ForEach{
        "+`"`$($($bit.$([Int32]$_) | Get-Random))`""
      }
    }) + "-split'(\d{8})').Where{`$_}.ForEach{[Char][Convert]::ToInt32(`$_,2)}"
    $x += ";.([ScriptBlock]::Create(-join`$`$))"

    Out-File -FilePath $OutFile -InputObject $x
  }
}
