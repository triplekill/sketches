#requires -version 5
using namespace System.IO
using namespace System.Text

Set-Alias -Name strings -Value Get-Strings
function Get-Strings {
  <#
    .SYNOPSIS
        Search strings in binary files.
    .DESCRIPTION
        `Get-Strings` just scans the file you pass it for Unicode or ASCII strings of a
        default length of 3 characters.
    .PARAMETER Path
        Specifies a file location. Wildcards are accepted.
    .PARAMETER LiteralPath
        Specifies a file location. The value of LiteralPath is used exactly as it is
        typed. No characters are interpreted as wildcards.
    .PARAMETER BytesToProcess
        Bytes of file to scan.
    .PARAMETER BytesOffset
        File offset at which to start scanning.
    .PARAMETER StringLength
        Minimum string length (default is 3).
    .PARAMETER StringOffset
        Print offset if file string was located.
    .PARAMETER Unicode
        Unicode-only search.
    .INPUTS
        System.String
    .OUTPUTS
        System.Object[]
    .EXAMPLE
        Get-Item .\file.bin | Get-Strings
        Process entire file, locate both ASCII and Unicode strings with default settings.
    .EXAMPLE
        Get-Strings .\file.bin -b 20 -f 100 -o
        Skip 100 bytes and process next 20 bytes of a file, show founded string offset.
    .EXAMPLE
        Get-Strings .\file.bin -u
        Process entire file but search only Unicode strings.
    .NOTES
        MIT
    .LINK
        None
  #>
  [CmdletBinding(DefaultParameterSetName='Path')]
  param(
    [Parameter(Mandatory,
               ParameterSetName='Path',
               Position=0,
               ValueFromPipeline,
               ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [String]$Path,

    [Parameter(Mandatory,
               ParameterSetName='LiteralPath',
               Position=0,
               ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [Alias('PSPath')]
    [String]$LiteralPath,

    [Parameter()][Alias('b')][UInt32]$BytesToProcess = 0,
    [Parameter()][Alias('f')][UInt32]$BytesOffset    = 0,
    [Parameter()][Alias('n')][Byte]  $StringLength   = 3,
    [Parameter()][Alias('o')][Switch]$StringOffset,
    [Parameter()][Alias('u')][Switch]$Unicode
  )

  begin {
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
      $PipelineInput = !$PSBoundParameters.ContainsKey('Path')
    }

    function private:Find-Strings([FileInfo]$File) {
      process {
        try {
          $fs = [File]::OpenRead($File.FullName)
          # unable to read beyond file length
          if ($BytesToProcess -ge $fs.Length -or $BytesOffset -ge $fs.Length) {
            throw [InvalidOperationException]::new('Out of stream.')
          }
          # offset has been defined
          if ($BytesOffset -gt 0) { [void]$fs.Seek($BytesOffset, [SeekOrigin]::Begin) }
          # bytes to process
          $buf = [Byte[]]::new(($fs.Length, $BytesToProcess)[$BytesToProcess -gt 0])
          [void]$fs.Read($buf, 0, $buf.Length)
          # show printable strings
          ([Regex]"[\x20-\x7E]{$StringLength,}").Matches(
            [Encoding]::"U$(('TF7', 'nicode')[$Unicode.IsPresent])".GetString($buf)
          ).ForEach{
            if ($StringOffset) { '{0}:{1}' -f $_.Index, $_.Value } else { $_.Value }
          }
        }
        catch { Write-Verbose $_ }
        finally {
          if ($fs) { $fs.Dispose() }
        }
      }
    }
  }
  process {}
  end {
    .({Find-Strings (Get-Item -LiteralPath $LiteralPath)},{
      Find-Strings ((Get-Item $Path -ErrorAction 0), $Path)[$PipelineInput]
    })[$PSCmdlet.ParameterSetName -eq 'Path']
  }
}
