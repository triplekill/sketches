function Get-DNComponents {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateScript({!!($script:file = Convert-Path -Path $_ -ErrorAction 0)})]
    [ValidateNotNullOrEmpty()]
    [String]$Path
  )

  end {
    $components = @{}

    try {
      [DirectoryServices.SortOption].Assembly.GetType(
        'System.DirectoryServices.ActiveDirectory.Utils'
      ).GetMethod(
        'GetDNComponents', [Reflection.BindingFlags]'NonPublic, Static'
      ).Invoke($null, @((
        Get-AuthenticodeSignature ($Path = $file)).SignerCertificate.Subject
      )).ForEach{$components[$_.Name] = $_.Value}
    }
    catch { Write-Verbose $_.Exception }

    if ($components.Count) { $components }
  }
}
