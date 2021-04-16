using namespace System.IO
using namespace System.Runtime.InteropServices

function Read-PEFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [SupportsWildcards()]
    [String]$Path
  )

  begin {
    function private:Get-Block([ScriptBlock]$Signature) {
      end {
        $block = @{}
        $Signature.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
          $type, $desc, $pack = $_.CommandElements.Value
          $type = $type -creplace 'Ptr', $Machine # replace UIntPtr with correct type
          $block[$desc] = $pack ? $(
            (0..($pack - 1)).ForEach{$br."Read$($type)"()}
          ) : $($br."Read$($type)"())
        }
        Set-Variable -Name block -Value ([PSCustomObject]$block) -Scope Script
      }
    }

    $RvaAndSizes = (
      'Export', 'Import', 'Resource', 'Exception', 'Security', 'BaseReloc', 'Debug',
      'Architecture', 'GlobalPtr', 'TLS', 'LoadConfig', 'BoundImport', 'IAT',
      'DelayImport', 'COMDescriptor', 'Reserved'
    )
  }
  process {}
  end {
    try {
      $br = [BinaryReader]::new(($fs = [File]::OpenRead((Convert-Path $Path))))
      Get-Block { # IMAGE_DOS_HEADER
        UInt16 e_magic
        UInt16 e_skipped 29 # read without checking
        Int32  e_lfanew
      }
      if ($block.e_magic -ne 23117) {
        throw [InvalidOperationException]::new('DOS signature has not been found.')
      }
      $fs.Position = $block.e_lfanew

      if ($br.ReadUInt32() -ne 17744) {
        throw [InvalidOperationException]::new('PE signature has not been found.')
      }
      Get-Block {
        UInt16 Machine
        UInt16 NumberOfSections
        UInt32 TimeDateStamp
        UInt32 PointerToSymbolTable
        UInt32 NumberOfSymbols
        UInt16 SizeOfOptionalHeader
        UInt16 Characteristics
      }
      $Machine = switch ($block.Machine) {0x014C{32}0x8664{64}default{throe}}
      $section = $block.NumberOfSections

      Get-Block {
        UInt16 Magic
        Byte   MajorLinkerVersion
        Byte   MinorLinkerVersion
        UInt32 SizeOfCode
        UInt32 SizeOfInitializedData
        UInt32 SizeOfUninitializedData
        UInt32 AddressOfEntryPoint
        UInt32 BaseOfCode
      }
      $linker = "$($block.MajorLinkerVersion).$($block.MinorLinkerVersion)"
      if ($Machine -eq 32) { [void]$br.ReadUInt32() }
      Get-Block {
        UIntPtr ImageBase
        UInt32 SectionAlignment
        UInt32 FileAlignment
        UInt16 MajorOperatingSystemVersion
        UInt16 MinorOperatingSystemVersion
        UInt16 MajorImageVersion
        UInt16 MinorImageVersion
        UInt16 MajorSubsystemVersion
        UInt16 MinorSubsystemVersion
        UInt32 Win32VersionValue
        UInt32 SizeOfImage
        UInt32 SizeOfHeaders
        UInt32 CheckSum
        UInt16 Subsystem
        UInt16 DllCharacteristicsB
        UIntPtr SizeOfStackReserve
        UIntPtr SizeOfStackCommit
        UIntPtr SizeOfHeapReserve
        UIntPtr SizeOfHeapCommit
        UInt32 LoaderFlags
        UInt32 NumberOfRvaAndSizes
      }
      (0..($block.NumberOfRvaAndSizes - 1)).ForEach{
        [PSCustomObject]@{
          Name = $RvaAndSizes[$_]
          RVA = $br.ReadUInt32()
          Size = $br.ReadUInt32()
        }
      }
    }
    catch { Write-Verbose $_ }
    finally {
      if ($br) { $br.Dispose() }
      if ($fs) { $fs.Dispose() }
    }
  }
}
