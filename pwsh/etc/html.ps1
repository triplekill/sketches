using namespace System.Runtime.InteropServices
# html parsing sample without third party libs
function Get-PythonStatus {
  end {
    if (($res = Invoke-WebRequest https://www.python.org).StatusCode -ne 200) {
      throw [InvalidOperationException]::new("Status: $($res.StatusCode)")
    }

    $com = New-Object -ComObject HTMLFile
    $com.write([ref]$res.Content)
    $com.getElementsByClassName('small-widget download-widget')[0].innerText
    [void][Marshal]::ReleaseComObject($com)
  }
}
