using namespace System.Xml
using namespace System.ServiceModel.Syndication

function Get-GitTag {
  <#
    .SYNOPSIS
        An attempt to generalize the receipt of latest versions of various
        projects such as Python, PowerShell and etc.
    .EXAMPLE
        Get-GitTag python cpython
    .EXAMPLE
        Get-GitTag rakudo rakudo
  #>
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
      }.Where{$_ -as [version]} | Sort-Object -Bottom 1
    }
    catch { Write-Verbose $_ }
    finally {
      if ($xml) { $xml.Dispose() }
    }
  }
}
