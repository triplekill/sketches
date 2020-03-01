function Get-CMake {
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateRange('c','z')]
    [ValidateNotNullOrEmpty()]
    [Char]$InstallRoot = 'E'
  )

  begin {
    $zip = "x$((86,64)[[Environment]::Is64BitOperatingSystem]).zip"

    if (( # get latest stable version through GitHub API
      $res = Invoke-WebRequest 'https://api.github.com/repos/kitware/cmake/releases/latest'
    ).StatusCode -ne 200) {
      throw [InvalidOperationException]::new($res.StatusDescription)
    }

    $res = [Uri]($res = ConvertFrom-Json -InputObject $res.Content).assets.Where{
      $_.name -like "*$zip" # cmake-***-win**-x**.zip
    }.browser_download_url
  }
  process {}
  end {
    .({[void](New-Item -Path $dir -ItemType Directory -Force)}, {
      (Get-ChildItem $dir).ForEach{Remove-Item $_.FullName -Force -Recurse:$_.PSIsContainer}
    })[(Test-Path ($dir = "$($InstallRoot):\cmake"))]

    Invoke-WebRequest -Uri $res -OutFile "$dir\$($res.Segments[-1])"
    Expand-Archive -Path "$dir\$($res.Segments[-1])" -Destination $dir
    (Get-ChildItem (Get-ChildItem $dir -Filter *win* -Directory)).ForEach{
      Move-Item -Path $_.FullName -Destination $dir -Force
    }
    (Get-ChildItem $dir -Filter *win*).ForEach{
      Remove-Item $_.FullName -Force -Recurse:$_.PSIsContainer
    }
  }
}
