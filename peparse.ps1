using namespace System.IO
using namespace System.Runtime.InteropServices

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

    function private:Convert-RvaToOfs([UInt32]$Rva) {
      end {
        $sections.ForEach{
          if (($Rva -ge $_.VirtualAddress) -and ($Rva -lt ($_.VirtualAddress + $_.Misc))) {
            return ($Rva - ($_.VirtualAddress - $_.PointerToRawData))
          }
        }
      }
    }

    <#function private:Get-ApiSet {
      end {
        $apiset = @{}
        New-Delegate ntdll { IntPtr RtlGetCurrentPeb }
        $to_i = "ToInt$(($sz = [IntPtr]::Size) * 8)"

        $ptr = [Marshal]::ReadIntPtr([IntPtr](
          $ntdll.RtlGetCurrentPeb.Invoke().$to_i() + ($sz -eq 8 ? 0x68 : 0x38)
        ))
        $asn, $mov = ($ptr -as [API_SET_NAMESPACE]), $ptr.$to_i()

        $pasne = [IntPtr]($asn.EntryOffset + $mov)
        for ($i = 0; $i -lt $asn.Count; $i++) {
          $asne = $pasne -as [API_SET_NAMESPACE_SET]
          $dll = [Marshal]::PtrToStringUni([IntPtr]($asne.NameOffset + $mov), $asne.NameLength / 2)

          $pasve = [IntPtr]($asne.ValueOffset + $mov)
          $mod = for ($j = 0; $j -lt $asne.ValueCount; $j++) {
            $asve = $pasve -as [API_SET_VALUE_ENTRY]
            [Marshal]::PtrToStringUni([IntPtr]($asve.ValueOffset + $mov), $asve.ValueLength / 2)
            $pasve = [IntPtr]($pasve.$to_i() + $asve::GetSize())
          }
          $apiset["$($dll).dll"] = $mod

          $pasne = [IntPtr]($pasne.$to_i() + $asne::GetSize())
        }
        $apiset
      }
    }#>
  }
  process {}
  end {
    try {
      $fs = [File]::OpenRead((Convert-Path $Path))
      $br = [BinaryReader]::new($fs)
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

      if (($export = $IMAGE_DATA_DIRECTORY.Where{$_.Directory -eq 'Export'}).VirtualAddress) {
        $fs.Position = Convert-RvaToOfs $export.VirtualAddress
        Resize-Buffer ([IMAGE_EXPORT_DIRECTORY]::GetSize())
        $IMAGE_EXPORT_DIRECTORY = ConvertTo-Structure $buf ([IMAGE_EXPORT_DIRECTORY])

        $fs.Position = Convert-RvaToOfs $IMAGE_EXPORT_DIRECTORY.Name
        while ($fs.ReadByte()) {} # moving to the list of exported functions
        $faddr, $bs = @{}, ([Int32]$IMAGE_EXPORT_DIRECTORY.Base)
        # getting exports, do not forget about order of functions and forwarded functions
        $names = (0..($IMAGE_EXPORT_DIRECTORY.NumberOfNames - 1)).ForEach{
          while (($c = $fs.ReadByte())) { $name += [Char]$c }
          $back = $fs.Position # checking forwarding
          while (($c = $fs.ReadByte())) { $fwrd += [Char]$c }
          if ($fwrd -notmatch '(\.|#)') {
            $fs.Position = $back
            $fwrd = [String]::Empty
          }
          [PSCustomObject]@{
            Name = $name; Forward = $fwrd; Type = $(
              switch -regex -casesensitive ($name) {'^[A-Z]'{0}'^_'{1}'^[a-z]'{2}}
            )
          }
          $name, $fwrd = ,[String]::Empty * 2
        }
        if ($names[0].Name -notmatch '^A') { $names = $names | Sort-Object Type, Name }
        $fs.Position = Convert-RvaToOfs $IMAGE_EXPORT_DIRECTORY.AddressOfFunctions
        (0..($IMAGE_EXPORT_DIRECTORY.NumberOfFunctions - 1)).ForEach{
          $faddr[$bs + $_] = $br.ReadUInt32().ToString('X8')
        }
        # time to show exports
        $fs.Position = Convert-RvaToOfs $IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals
        $export = (0..($IMAGE_EXPORT_DIRECTORY.NumberOfNames - 1)).ForEach{
          [PSCustomObject]@{
            Ordinal = ($ord = $bs + $br.ReadUInt16())
            RVA = $names[$_].Forward ? '' : $faddr[$ord]
            Name = $names[$_].Name
            ForwardedTo = $names[$_].Forward
          }
        }
      }

      if (($import = $IMAGE_DATA_DIRECTORY.Where{$_.Directory -eq 'Import'}).VirtualAddress) {
        $fs.Position = Convert-RvaToOfs $import.VirtualAddress
        $apiset = Get-ApiSet
        (0..($import.Size / [IMAGE_IMPORT_DESCRIPTOR]::GetSize() - 2)).ForEach{
          $name = [String]::Empty
          Resize-Buffer ([IMAGE_IMPORT_DESCRIPTOR]::GetSize())
          $IMAGE_IMPORT_DESCRIPTOR = ConvertTo-Structure $buf ([IMAGE_IMPORT_DESCRIPTOR])
          $cur = $fs.Position

          $fs.Position = Convert-RvaToOfs $IMAGE_IMPORT_DESCRIPTOR.Name
          while (($c = $fs.ReadByte())) { $name += [Char]$c }
          #($dll = $apiset[$name]) ? "$name (points to $dll)" : $name
          $name
          $fs.Position = $cur
        }
      }

      <#$IMAGE_DOS_HEADER
      $stub | Format-Table -AutoSize
      $IMAGE_NT_HEADERS.FileHeader
      $IMAGE_NT_HEADERS.OptionalHeader
      $IMAGE_DATA_DIRECTORY | Format-Table -AutoSize
      $sections | Format-Table -AutoSize
      $IMAGE_EXPORT_DIRECTORY
      $export#>
    }
    catch { Write-Verbose $_ }
    finally {
      if ($br) { $br.Dispose() }
      if ($fs) { $fs.Dispose() }
      if ($buf) { $buf.Clear() }
    }
  }
}
