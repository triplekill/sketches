#requires -version 6
using namespace System.Net.Sockets
using namespace System.Net.Security

function Get-HostSSLCert {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Address, # for example, github.com

    [Parameter(Position=1)]
    [Int32]$Port = 443
  )

  process {
    $callback = {param($sender, $sert, $chain, $err) return $true}

    try {
      $tcp = [TcpClient]::new()
      $tcp.Connect($Address, $Port)

      $str = $tcp.GetStream()
      $ssl = [SslStream]::new($str, $true, $callback)
      $ssl.AuthenticateAsClient('')
      $ssl.RemoteCertificate # use Dispose() to release resource
    }
    catch { $_ }
    finally {
      ($ssl, $str, $tcp).ForEach{ if ($_) { $_.Dispose() } }
    }
  }
}
