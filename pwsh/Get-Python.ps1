function Get-Python {
  <#
    .SYNOPSIS
        Deploy the latest embedded version of Python.
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateRange('c','z')]
    [ValidateNotNullOrEmpty()]
    [Char]$InstallRoot = 'E',

    [Parameter()]
    [Switch]$ChmRequired,

    [Parameter()]
    [Switch]$PipRequired
  )

  begin {
    $zip = "python-%s-embed-$(('win32','amd64')[[Environment]::Is64BitOperatingSystem]).zip"

    if (($res = Invoke-WebRequest ($url = 'https://www.python.org/ftp/python/')).StatusCode -ne 200) {
      throw [InvalidOperationException]::new($res.StatusDescription)
    }

    $zip = $res.Links.href.Where{$_.StartsWith('3')}[-1..-5].ForEach{
      try {
        $head = Invoke-WebRequest ($arc = "$url$_$($zip -replace '%s', $_.Trim('/'))") -Method HEAD
        if ($head.StatusCode -eq 200) {
          $head = $head.Headers
          [PSCustomObject]@{
            Package   = [Uri]$arc
            Length    = $head.'Content-Length'[0]
            TimeStamp = $head.'Last-Modified'[0]
          }
        }
      }
      catch {}
    }[0]
    Write-Verbose $zip
  }
  process {}
  end {
    if ((Read-Host "Install $($zip.Package.Segments[-2].Trim('/')) version? [y/n]") -eq 'Y') {
      .({[void](New-Item -Path $dir -ItemType Directory -Force) # root path
        ('DLLs', 'Doc', 'Lib').ForEach{ # subdirectories
          [void](New-Item -Path "$dir\$_" -ItemType Directory -Force)
        }
      }, { # remove previous installation files
        Get-ChildItem -Path "$dir\*" -File -Recurse | Remove-Item -Force
      })[(Test-Path ($dir = "$($InstallRoot):\python"))]

      $out = $zip.Package.Segments[-1]
      if ($ChmRequired) {
        $chm = "$([Regex]::Match($out, '[^-]*-[^-]*').Value -replace '(\.|-)').chm"
        Invoke-WebRequest ($zip.Package.AbsoluteUri -replace '/[^/]*$', "/$chm") -OutFile "$dir\Doc\$chm"
      }
      Invoke-WebRequest $zip.Package -OutFile "$dir\$out"
      Expand-Archive -Path "$dir\$out" -Destination $dir
      Remove-Item -Path "$dir\$out" -Force
      ('*.pyd', 'lib*.dll', 'sqlite*.dll').ForEach{
        Move-Item -Path "$dir\$_" -Destination "$dir\DLLs"
      }
      Expand-Archive -Path "$dir\python*.zip" -Destination "$dir\Lib"
      ('*.txt', '*._pth', '*.zip').ForEach{Remove-Item -Path "$dir\$_" -Force}

      if ($PipRequired) {
        Invoke-WebRequest 'https://bootstrap.pypa.io/get-pip.py' -OutFile "$dir\get-pip.py"
        & "$dir\python.exe" "$dir\get-pip.py"
        Remove-Item -Path "$dir\get-pip.py" -Force
      }
    }
  }
}
