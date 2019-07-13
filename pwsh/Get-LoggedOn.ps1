#requires -version 6.1
using namespace System.Reflection
using namespace System.ComponentModel

function Get-LoggedOn {
  [CmdletBinding()]param()

  process {
    $rk, $ft = (Get-Item 'HKCU:\Volatile Environment'), [Int32[]]::new(2)
    if (!($res = [AppDomain]::CurrentDomain.GetAssemblies().Where{
      $_.ManifestModule.ScopeName.Equals('Microsoft.Win32.Registry.dll')
    }[0].GetType('Interop+Advapi32').GetMethod(
      'RegQueryInfoKey', [BindingFlags]'NonPublic, Static'
    ).Invoke($null, @($rk.Handle, $null, $null, [IntPtr]::Zero,
    $null, $null, $null, $null, $null, $null, $null, $ft)))) {
      [DateTime]::FromFileTime(
        ([Int64]$ft[1] -shl 32) -bor [BitConverter]::ToUInt32(
          [BitConverter]::GetBytes($ft[0]), 0
        )
      )
    }
    else { [Win32Exception]::new($res) }
    $rk.Dispose()
  }
}
