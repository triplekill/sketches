using namespace System.Xml
using namespace System.Text
using namespace System.ServiceModel.Syndication

function Get-GitTag {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Owner,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNullOrEmpty()]
    [String]$Repo
  )

  end {
    try {
      $xml = [XmlReader]::Create("https://github.com/$Owner/$Repo/tags.atom")
      [SyndicationFeed]::Load($xml).Items.Links.ForEach{
        $_.Uri.Segments[-1] -split '^[^\d+]*' -replace '_', '.'
      }.Where{$_ -as [Version]} | Sort-Object -Bottom 1
    }
    catch { Write-Verbose $_ }
    finally {
      if ($xml) { $xml.Dispose() }
    }
  }
}

function ConvertFrom-UnsafeHash {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$Hash
  )

  end {
    $url = "https://www.virustotal.com/vtapi/v2/file/report?apikey=$(
      '4e3202fdbe953d628f650229af5b3eb49cd46b2d3bfe5546ae3c5fa48b554e0c'
    )&resource=$Hash"

    if (($res = Invoke-WebRequest $url).StatusCode -ne 200) {
      throw [InvalidOperationException]::new("Status: $($res.StatusCode)")
    }

    ($res | ConvertFrom-Json).sha256
  }
}

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
      throw [InvalidOperationException]::new("Status: $($res.StatusCode)")
    }

    $res, $lnk = $res.Content, $res.Links # $res can be a bytes array
    $res = $res -is [Array] ? [Encoding]::Ascii.GetString($res) : $res
    switch ($Class) {
      'csv' {
        (ConvertFrom-Csv -Delimiter $Delimiter -InputObject $res).Where{
          $_."$($Criteria[0])" -match $Criteria[1]
        }."$($Criteria[2])"
      }
      'html' {
        $i = (($arr = $res.Split("`n")) |
          Select-String -Pattern ($lnk.Where{
            $_.href -match "$Criteria`$"}.outerHTML)).LineNumber + $Offset
        if (($sum = ( # trying to get SHA256 via VirusTotal.com
          $arr[$i] -replace '\s*<[^>]*>' -split ':\s*'
        )[-1]).Length -lt 64) {
          $sum = ConvertFrom-UnsafeHash $sum
        }
        $sum
      }
      'hybrid' {
        $res = ($res | ConvertFrom-Json).Where{
          $_.tag_name -eq $Criteria[0]}.body.Split("`n")
        $res[($res | Select-String -Pattern $Criteria[1]
          ).LineNumber].Trim([Char[]]('-',' ')).ToLower()
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

function Get-PkgData {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('cmake', 'golang', 'julia', 'node', 'php', 'python', 'pwsh')]
    [ValidateNotNullOrEmpty()]
    [String]$Name
  )

  begin {
    $lst = @{
      cmake = @{
        tag = @{Owner = 'kitware';Repo = 'cmake'}
        sum = @{
          Url = 'https://github.com/Kitware/CMake/releases/download/v%{ver}/cmake-%{ver}-SHA-256.txt'
          Class = 'text'
          Criteria = 'cmake-%{ver}-win64-x64.zip'
        }
        url = 'https://github.com/Kitware/CMake/releases/download/v%{ver}/cmake-%{ver}-win64-x64.zip'
      }

      golang = @{
        tag = @{Owner = 'golang';Repo = 'go'}
        sum = @{
          Url = 'https://golang.org/dl/'
          Class = 'html'
          Offset = 4
          Criteria = 'go%{ver}.windows-amd64.zip'
        }
        url = 'https://golang.org/dl/go%{ver}.windows-amd64.zip'
      }

      julia = @{
        tag = @{Owner = 'julialang';Repo = 'julia'}
        sum = @{
          Url = 'https://julialang-s3.julialang.org/bin/checksums/julia-%{ver}.sha256'
          Class = 'text'
          Criteria = 'julia-%{ver}-win64.zip'
        }
        url = 'https://julialang-s3.julialang.org/bin/winnt/x64/%{mnm}/julia-%{ver}-win64.zip'
      }

      node = @{
        tag = @{Owner = 'nodejs';Repo = 'node'}
        sum = @{
          Url = 'https://nodejs.org/dist/latest-v%{maj}.x/SHASUMS256.txt'
          Class = 'text'
          Criteria = 'node-v%{ver}-win-x64.zip'
        }
        url = 'https://nodejs.org/dist/latest-v%{maj}.x/node-v%{ver}-win-x64.zip'
      }

      php = @{
        tag = @{Owner = 'php';Repo = 'php-src'}
        sum = @{
          Url = 'https://windows.php.net/downloads/releases/sha256sum.txt'
          Class = 'text'
          Criteria = '\*php-%{ver}-Win32-vc15-x64.zip'
        }
        url = 'https://windows.php.net/downloads/releases/php-%{ver}-Win32-vc15-x64.zip'
      }

      python = @{
        tag = @{Owner = 'python';Repo = 'cpython'}
        sum = @{
          Url = 'https://www.python.org/downloads/release/python-%{raw}/'
          Class = 'html'
          Criteria = 'python-%{ver}-embed-amd64.zip'
        }
        url = 'https://www.python.org/ftp/python/%{ver}/python-%{ver}-embed-amd64.zip'
      }

      pwsh = @{
        tag = @{Owner = 'powershell';Repo = 'powershell'}
        sum = @{
          Url = 'https://api.github.com/repos/PowerShell/PowerShell/releases'
          Class = 'hybrid'
          Criteria = ('v%{ver}', 'powershell-%{ver}-win-x64.zip')
        }
        url = 'https://github.com/PowerShell/PowerShell/releases/download/%{ver}/PowerShell-%{ver}-win-x64.zip'
      }
    }
  }
  process {}
  end {
    $par = $lst[$Name].tag
    $ver = Get-GitTag @par
    $mnm = Select-Object -InputObject ([Version]$ver) -Property Major, Minor
    $maj = $mnm.Major
    $mnm = "$($mnm.Major).$($mnm.Minor)"

    $par = $lst[$Name].sum
    $par.Url = $par.Url -replace '%\{raw\}', ($ver -replace '\.', '')
    $par.Url = $par.Url -replace '%\{ver\}', $ver
    $par.Url = $par.Url -replace '%\{maj\}', $maj
    $par.Url = $par.Url -replace '%\{mnm\}', $mnm
    $par.Criteria = $par.Criteria.ForEach{$_ -replace '%\{ver\}', $ver}
    $lst[$Name].url = $lst[$Name].url -replace '%\{maj\}', $maj
    $lst[$Name].url = $lst[$Name].url -replace '%\{mnm\}', $mnm

    [PSCustomObject]@{
      Link = $lst[$Name].url -replace '%\{ver\}', $ver
      SHA256 = Get-HashFromUrl @par
    }
  }
}

#('cmake', 'golang', 'julia', 'node', 'php', 'python', 'pwsh').ForEach{Get-PkgData $_} | ConvertTo-Json
