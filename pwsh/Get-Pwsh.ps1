#requires -version 6
function Get-Pwsh {
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [String]$Path = $PWD.Path,

    [Parameter()][Switch]$Validate,
    [Parameter()][Switch]$NoPreview,
    [Parameter()][Switch]$OnlyReleaseNotes
  )

  begin {
    if ($PSBoundParameters.Path -or
        $PSBoundParameters.Validate -and
        $PSBoundParameters.OnlyReleaseNotes) {
      throw [InvalidOperationException]::new('Invalid switch scope.')
    }

    $url = 'https://api.github.com/repos/PowerShell/PowerShell/releases'
    $json = Invoke-WebRequest $url | ConvertFrom-Json

    if ($NoPreview) { $json = $json.Where{!$_.prerelease}[0] }

    if ($OnlyReleaseNotes) {
      $notes = $json[0].body.Split("`n")
      $notes[0..(($notes | Select-String '^###\s+?sha256').LineNumber - 2)]
      break
    }

    if ($Validate) {
      $hashes, $table = @{}, $json[0].body.Split(
        "`n", [StringSplitOptions]::RemoveEmptyEntries
      )
      $table = $table[++(
        $table | Select-String '^###\s+?sha256'
      ).LineNumber..$table.Length]
      for ($i = 0; $i -lt $table.Length; $i += 2) {
        $block = $table[$i..($i + 1)].Trim(@(' ', '-'))
        $hashes[$block[0].Trim()] = $block[1].Trim()
      }
    }
  }
  process {}
  end {
    if ($IsLinux) {
      $os = @{}
      (Select-String '^((?:version_)?id)="?([^"\.]*)' /etc/os-release
      ).Matches.ForEach{$os[$_.Groups[1].Value] = $_.Groups[2].Value}
      $os = "*$(.({"$($os.id).$($os.version_id)"},{'linux'})[$os.id -eq 'linux'])*"
    }

    if (!(Test-Path variable:os)) {
      $os = "*$(('osx', 'win')[$IsWindows])*"
    }

    if (($pkg = $json[0].assets.Where{$_.name -like $os}).Count -gt 1) {
      $i = 0
      $pkg.name.ForEach{"  `e[36;1m{0}`e[32;0m: {1}" -f ++$i, $_}

      if (($num = Read-Host "`e[32;1mSelect required package`e[32;0m") -notin 1..$i) {
        throw [InvalidOperationException]::new('Invalid package number.')
      }

      $pkg = $pkg[$num - 1]
    }

    $Path = Join-Path $Path "$($pkg.name)"
    Invoke-WebRequest -Uri $pkg.browser_download_url -OutFile $Path

    if ($pkg.size -ne (Get-Item $Path).Length) {
      throw [InvalidOperationException]::new('Not finished download.')
    }

    if ($Validate) {
      if ((Get-FileHash $Path).Hash -ne $hashes[$pkg.name]) {
        Write-Warning 'Hash mismatch.'
        break
      }
      "`e[33;1mOK`e[32;0m"
    }
  }
}
