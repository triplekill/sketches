#requires -version 7
function Get-PowerStatus {
  [CmdletBinding()]param()

  process {
    Add-Type -AssemblyName System.Windows.Forms
    [Windows.Forms.PowerStatus].GetConstructor(
      [Reflection.BindingFlags]'Instance, NonPublic',
      $null, [Type[]]@(), $null
    ).Invoke($null)
  }
}
