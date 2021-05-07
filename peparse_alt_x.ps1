using namespace System.IO
using namespace System.Runtime.InteropServices

function Get-PeInfo {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$Path
  )

  begin {
    function private:Get-Block([String]$Name, [ScriptBlock]$Fields) {
      end {
        if (!($var = $ExecutionContext.SessionState.PSVariable.Get($Name)).Value) {
          $var = Set-Variable -Name $Name -Value @{} -Scope Script -PassThru
        }

        $Fields.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
          $type, $desc, $pack = $_.CommandElements.Value
          $type = $type -creplace 'Ptr', $IMAGE_FILE_HEADER.Machine
          $var.Value[$desc] = $pack ? $(
            (0..($pack - 1)).ForEach{$br."Read$($type)"()}
          ) : $($br."Read$($type)"())
        }
      }
    }

    function private:Convert-RvaToRaw([UInt32]$Rva) {
      end {
        $AlignSection = {
          param([UInt32]$Size)
          ($Size -band (
            ($align = $IMAGE_OPTIONAL_HEADER.SectionAlignment) - 1)
          ) ? (($Size -band ($align * -1)) + $align) : $Size
        }

        $sections.ForEach{
          if (($Rva -ge $_.VirtualAddress) -and (
            $Rva -lt ($_.VirtualAddress + (& $AlignSection $_.Size))
          )) {return ($Rva - ($_.VirtualAddress - $_.PointerToRawData))}
        }
      }
    }
  }
  process {}
  end {
    try {
      $br = [BinaryReader]::new(($fs = [File]::OpenRead((Convert-Path $Path))))
      Get-Block IMAGE_DOS_HEADER {
        UInt16 e_magic
        UInt16 e_skipped 29
        Int32  e_lfanew
      }
      if ($IMAGE_DOS_HEADER.e_magic -ne 0x5A4D) {
        throw [InvalidOperationException]::new('DOS signature has not been found.')
      }

      $fs.Position = $IMAGE_DOS_HEADER.e_lfanew
      if ($br.ReadUInt32() -ne 0x4550) {
        throw [InvalidOperationException]::new('PE signature has not been found.')
      }
      Get-Block IMAGE_FILE_HEADER {
        UInt16 Machine
        UInt16 NumberOfSections
        UInt32 Skipped 3
        UInt16 SizeOfOptionalHeader
        UInt16 Characteristics
      }
      $IMAGE_FILE_HEADER.Machine = $IMAGE_FILE_HEADER.Machine -eq 0x014C ? 32 : 64
      $AfterOptionalHeader = $fs.Position + $IMAGE_FILE_HEADER.SizeOfOptionalHeader
      Get-Block IMAGE_OPTIONAL_HEADER {
        UInt16 Magic
        Byte   Linker 2
        UInt32 SizeOfCode
        UInt32 SizeOfData 2
        UInt32 AddressOfEntryPoint
        UInt32 BaseOfCode
      }
      if ($IMAGE_OPTIONAL_HEADER.Magic -eq 0x10B) {
        $IMAGE_OPTIONAL_HEADER.BaseOfData = $br.ReadUInt32()
      }
      Get-Block IMAGE_OPTIONAL_HEADER {
        UIntPtr ImageBase
        UInt32  SectionAlignment
        UInt32  FileAlignment
        UInt16  Versions 6
        UInt32  Skipped 4
        UInt16  Subsystem
      }
      $fs.Position = $AfterOptionalHeader - 0x0F * 8
      Get-Block ImportDirectory {
        UInt32 Rva
        UInt32 Size
      }
      $fs.Position = $AfterOptionalHeader
      $sections = (0..($IMAGE_FILE_HEADER.NumberOfSections - 1)).ForEach{
        [PSCustomObject]@{
          Name = [String]::new($br.ReadBytes(0x08)).Trim("`0")
          Size = $br.ReadUInt32()
          VirtualAddress = $br.ReadUInt32()
          SizeOfRawData = $br.ReadUInt32()
          PointerToRawData = $br.ReadUInt32()
        }
        $fs.Position += 0x10
      }
      if ($ImportDirectory.Rva) {
        $fs.Position = Convert-RvaToRaw $ImportDirectory.Rva
        $dlls = (0..($ImportDirectory.Size / 0x14 - 2)).ForEach{
          $name = [String]::Empty
          $gch = [GCHandle]::Alloc($br.ReadBytes(0x14), [GCHandleType]::Pinned)
          $cur = $fs.Position
          $fs.Position = Convert-RvaToRaw ([Marshal]::ReadInt32($gch.AddrOfPinnedObject(), 0x0C))
          $gch.Free()

          while (($c = $fs.ReadByte())) { $name += [Char]$c }
          $name
          $fs.Position = $cur
        }
      }

      [PSCustomObject]@{
        Type = $IMAGE_OPTIONAL_HEADER.Magic -eq 0x20B ? 'PE+' : 'PE'
        Linker = $IMAGE_OPTIONAL_HEADER.Linker -join '.'
        EP = '0x{0:X}' -f $IMAGE_OPTIONAL_HEADER.AddressOfEntryPoint
        Sections = Format-Table -InputObject $sections -AutoSize
        Imports = $dlls
      }
    }
    catch { Write-Verbose $_ }
    finally {
      if ($br) { $br.Dispose() }
      if ($fs) { $fs.Dispose() }
    }
  }
}
