using namespace System.IO

#. .\pelib.ps1
#. .\tiny.ps1

function Read-PEFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [String]$Path
  )

  begin {
    function private:Resize-Buffer([Int32]$Size) {
      end {
        [Array]::Resize([ref]$buf, $Size)
        [void]$fs.Read($buf, 0, $buf.Length)
      }
    }
  }
  process {}
  end {
    try {
      $fs = [File]::OpenRead((Convert-Path $Path))
      $buf = [Byte[]]::new([IMAGE_DOS_HEADER]::GetSize())
      [void]$fs.Read($buf, 0, $buf.Length)

      $IMAGE_DOS_HEADER = ConvertTo-Structure $buf ([IMAGE_DOS_HEADER])
      if ($IMAGE_DOS_HEADER.e_magic -cne 'DOS') {
        throw [InvalidOperationException]::new('Unknown file format.')
      }
      Resize-Buffer ($IMAGE_DOS_HEADER.e_lfanew - [IMAGE_DOS_HEADER]::GetSize())
      $stub = Format-Hex -InputObject $buf |
                       Select-Object @{N='Offset';E={$_.HexOffset}},@{N='Bytes';E={$_.HexBytes}},Ascii

      Resize-Buffer ([IMAGE_NT_HEADERS64]::GetSize())
      $IMAGE_NT_HEADERS = ConvertTo-Structure $buf ([IMAGE_NT_HEADERS64])
      if ($IMAGE_NT_HEADERS.Signature -cne 'Valid') {
        throw [InvalidOperationException]::new('Invalid PE file.')
      }
      if ($IMAGE_NT_HEADERS.FileHeader.Machine -ne 0x8664) {
        $fs.Position -= [IMAGE_NT_HEADERS64]::GetSize() - [IMAGE_NT_HEADERS32]::GetSize()
        $IMAGE_NT_HEADERS = ConvertTo-Structure $buf ([IMAGE_NT_HEADERS32])
      }

      $IMAGE_DATA_DIRECTORY = (0..($IMAGE_NT_HEADERS.OptionalHeader.NumberOfRvaAndSizes - 1)).ForEach{
        $datadir = $IMAGE_NT_HEADERS.OptionalHeader.DataDirectory[$_]
        [PSCustomObject]@{
          Directory = [IMAGE_DIRECTORY_ENTRY]$_
          VirtualAddress = $datadir.VirtualAddress
          Size = $datadir.Size
        }
      }

      Resize-Buffer ([IMAGE_SECTION_HEADER]::GetSize() * $IMAGE_NT_HEADERS.FileHeader.NumberOfSections)
      $sections = ($buf |
                Group-Object {[Math]::Floor($script:i++ / [IMAGE_SECTION_HEADER]::GetSize())}).ForEach{
        ConvertTo-Structure $_.Group ([IMAGE_SECTION_HEADER])
      }

      <#$IMAGE_DOS_HEADER
      $stub | Format-Table -AutoSize
      $IMAGE_NT_HEADERS.FileHeader
      $IMAGE_NT_HEADERS.OptionalHeader
      $IMAGE_DATA_DIRECTORY | Format-Table -AutoSize
      $sections | Format-Table -AutoSize#>
    }
    catch { Write-Verbose $_ }
    finally {
      if ($fs) { $fs.Dispose() }
    }
  }
}
