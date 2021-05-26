using namespace System.IO
using namespace System.Runtime.InteropServices

function Get-PeDepends {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateScript({!!($script:file = Convert-Path $_ -ErrorAction 0)})]
    [ValidateNotNullOrEmpty()]
    [String]$Path
  )

  begin {
    $VerbosePreference, $Path = 'Continue', $file
    function private:Get-Block([String]$Name, [ScriptBlock]$Fields) {
      end {
        if (!($var = $ExecutionContext.SessionState.PSVariable.Get($Name)).Value) {
          $var = Set-Variable -Name $Name -Value @{} -Scope Script -PassThru
        }

        $Fields.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
          $type, $desc, $pack = $_.CommandElements.Value
          #$type = $type -creplace 'Ptr', $IMAGE_FILE_HEADER.Machine
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
          ($Size -band ($SectionAlignment - 1)) ? (
            ($Size -band ($SectionAlignment * -1)) + $SectionAlignment
          ) : $Size
        }

        $sections.ForEach{
          if (($Rva -ge $_.VirtualAddress) -and (
            $Rva -lt ($_.VirtualAddress + (& $AlignSection $_.Size))
          )) {return ($Rva - ($_.VirtualAddress - $_.PointerToRawData))}
        }
      }
    }
  }
  #process {}
  end {
    try {
      $br = [BinaryReader]::new(($fs = [File]::OpenRead($Path)))
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
      <#$IMAGE_FILE_HEADER.Machine = switch ($IMAGE_FILE_HEADER.Machine) {
        0x014C {0x20} 0x8664 { 0x40 } default {throw}
      }#>
      if (($IMAGE_FILE_HEADER.Characteristics -band 0x2000) -eq 0x2000) {
        Write-Verbose 'Seems that file you are trying to parse is a DLL.'
      }
      $AfterOptionalHeader = $fs.Position + $IMAGE_FILE_HEADER.SizeOfOptionalHeader

      $fs.Position += 0x20
      $SectionAlignment = $br.ReadUInt32()

      $fs.Position = $AfterOptionalHeader - 0x0F * 8
      Get-Block ImportDirectory {
        UInt32 Rva
        UInt32 Size
      }
      if (!$ImportDirectory.Rva) {
        throw [InvalidOperationException]::new('There are no imports.')
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

      $fs.Position = Convert-RvaToRaw $ImportDirectory.Rva
      (0..($ImportDirectory.Size / 0x14 - 2)).ForEach{
        $name = [String]::Empty
        $gch = [GCHandle]::Alloc($br.ReadBytes(0x14), [GCHandleType]::Pinned)
        $cur = $fs.Position
        $fs.Position = Convert-RvaToRaw ([Marshal]::ReadInt32($gch.AddrOfPinnedObject(), 0x0C))
        $gch.Free()

        while (($c = $fs.ReadByte())) { $name += [Char]$c }
        $name.ToLower()
        $fs.Position = $cur
      } | Sort-Object
    }
    catch { Write-Verbose $_ }
    finally {
      ($br, $fs).ForEach{ if ($_) { $_.Dispose() } }
    }
  }
}
