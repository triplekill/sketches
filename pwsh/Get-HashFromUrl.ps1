using namespace System.Text

function Get-HashFromUrl {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Uri]$Url,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('csv', 'html', 'hybrid', 'text')]
    [String]$Class = 'text',

    [Parameter()]
    [AllowEmptyCollection()]
    [String[]]$Criteria,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]$Delimiter = "`t",

    [Parameter()]
    [UInt16]$Offset = 2
  )

  end {
    if (($res = Invoke-WebRequest -Uri $Url).StatusCode -ne 200) {
      thrw [InvalidOperationException]::new("Status: $($res.StatusCode)")
    }

    $res, $lnk = $res.Content, $res.Links
    $res = $res -is [Array] ? [Encoding]::Ascii.GetString($res) : $res
    switch ($Class) {
      'csv' {
        (ConvertFrom-Csv -Delimiter $Delimiter -InputObject $res).Where{
          $_."$($Criteria[0])" -match $Criteria[1]
        }."$($Criteria[2])"
      }
      'html' {
        $i = (($arr = $res.Split("`n")) |
          Select-String ($lnk.Where{$_.href -match "$Criteria`$"}.outerHTML)
        ).LineNumber + $Offset
        ($arr[$i] -replace '\s*<[^>]*>' -split ':\s*')[-1]
      }
      'hybrid' {
        $res = ($res | ConvertFrom-Json).Where{
          $_.tag_name -eq $Criteria[0]
        }.body.Split("`n")
        $res[($res | Select-String -Pattern $Criteria[1]
        ).LineNumber].Trim([Char[]]('-', ' ')).ToLower()
      }
      'text' {
        $Criteria.Count -eq 0 ? $res : (
          (Select-String -Pattern "(\S+)\s+$Criteria" -InputObject $res
          ).Matches.Groups[1].Value
        )
      }
    } # switch
  }
}

<#
# test block
#
$param = @{ # returns MD5
  Url = 'https://www.python.org/downloads/release/python-390/'
  Class = 'html'
  Criteria = 'python-3.9.0-amd64.exe'
}
Get-HashFromUrl @param

$param.Url = 'https://www.lua.org/ftp/' # SHA1
$param.Criteria = 'lua-5.4.1.tar.gz'
Get-HashFromUrl @param

$param.Url = 'https://golang.com/dl/' # SHA256
$param.Criteria = 'go1.15.3.windows-amd64.msi'
$param.Offset = 4
Get-HashFromUrl @param

$param.Remove('Offset')
$param.Url = 'https://cache.ruby-lang.org/pub/ruby/index.txt'
$param.Class = 'csv'
$param.Criteria = ('url', 'ruby-2.7.2.tar.gz', 'sha256')
Get-HashFromUrl @param

$param.Remove('Criteria')
$param.Url = 'https://www.cpan.org/src/5.0/perl-5.32.0.tar.gz.sha256.txt'
$param.Class = 'text'
Get-HashFromUrl @param

$param.Url = 'https://windows.php.net/downloads/releases/sha256sum.txt'
$param.Criteria = ('\*php-7.4.11-nts-Win32-vc15-x64.zip')
Get-HashFromUrl @param

$param.Url = 'https://api.github.com/repos/PowerShell/PowerShell/releases'
$param.Class = 'hybrid'
$param.Criteria = ('v7.0.3', 'powershell-7.0.3-win-x64.zip')
Get-HashFromUrl @param
#>
