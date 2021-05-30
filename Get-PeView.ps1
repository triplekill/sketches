using namespace System.IO

function Get-PeView {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateScript({!!($script:file = Convert-Path $_ -ErrorAction 0)})]
    [ValidateNotNullOrEmpty()]
    [String]$Path,

    [Parameter()][Alias('d')][Switch]$DataDir,
    [Parameter()][Alias('s')][Switch]$Section,
    [Parameter()][Alias('e')][Switch]$Exports,
    [Parameter()][Alias('i')][Switch]$Imports
  )

  begin {
    $Path, $RvaAndSizes = $file, (
      'Export', 'Import', 'Resource', 'Exception', 'Security', 'BaseReloc', 'Debug', 'Architecture', 'GlobalPtr',
      'TLS', 'LoadConfig', 'BoundImport', 'IAT', 'DelayImport', 'COMDescriptor', 'Reserved'
    )
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

    function private:Convert-RvaToRaw([UInt32]$Rva, [UInt32]$Align=$IMAGE_OPTIONAL_HEADER.FileAlignment) {
      end {
        [ScriptBlock]$Aligner = {
          param([UInt32]$Size) ($Size -band ($Align - 1)) ? (($Size -band ($Align * -1)) + $Align) : $Size
        }

        $sections.ForEach{
          if (($Rva -ge $_.VirtualAddress) -and (
            $Rva -lt ($_.VirtualAddress + (& $Aligner $_.VirtualSize))
          )) {return ($Rva - ($_.VirtualAddress - $_.PointerToRawData))}
        }
      }
    }

    function private:Get-RawString([UInt32]$Offset, [Switch]$NoMove) {
      end {
        $cur = $fs.Position
        $fs.Position = $Offset
        while (($c = $br.ReadChar())) { $name += $c }
        if ($NoMove) { $fs.Position = $cur }
        $name
      }
    }
  }
  #process {}
  end {
    try {
      $br = [BinaryReader]::new(($fs = [File]::OpenRead($Path)))
      Write-Verbose "Image total length 0x$($fs.Length.ToString('X'))"
      Get-Block IMAGE_DOS_HEADER {
        UInt16 e_magic
        UInt16 e_cblp
        UInt16 e_cp
        UInt16 e_crlc
        UInt16 e_cparhdr
        UInt16 e_minalloc
        UInt16 e_maxalloc
        UInt16 e_ss
        UInt16 e_sp
        UInt16 e_csum
        UInt16 e_ip
        UInt16 e_cs
        UInt16 e_lfarlc
        UInt16 e_ovno
        UInt16 e_res 4
        UInt16 e_oemid
        UInt16 e_oeminfo
        UInt16 e_res2 10
        Int32  e_lfanew
      }
      if ($IMAGE_DOS_HEADER.e_magic -ne 0x5A4D) {
        throw [InvalidOperationException]::new('DOS signature has not been found.')
      }
      Write-Verbose 'Found the DOS signature'

      $fs.Position = $IMAGE_DOS_HEADER.e_lfanew
      Write-Verbose "Image NT headers offset 0x$($fs.Position.ToString('X'))"
      if ($br.ReadUInt32() -ne 0x4550) {
        throw [InvalidOperationException]::new('PE signature has not been found.')
      }
      Write-Verbose 'Found the PE signature'
      Write-Verbose "Image file header offset 0x$($fs.Position.ToString('X'))"
      Get-Block IMAGE_FILE_HEADER {
        UInt16 Machine
        UInt16 NumberOfSections
        UInt32 TimeDateStamp
        UInt32 PointerToSymbolTable
        UInt32 NumberOfSymbols
        UInt16 SizeOfOptionalHeader
        UInt16 Characteristics
      }
      $IMAGE_FILE_HEADER.Machine = switch ($IMAGE_FILE_HEADER.Machine) {
        0x014C {0x20} 0x8664 {0x40}
        default{throw [InvalidOperationException]::new('Unknown machine type.')}
      }
      Write-Verbose "Image optional header offset 0x$($fs.Position.ToString('X'))"
      Get-Block IMAGE_OPTIONAL_HEADER {
        UInt16 Magic
        Byte   MajorLinkerVersion
        Byte   MinorLinkerVersion
        UInt32 SizeOfCode
        UInt32 SizeOfInitializedData
        UInt32 SizeOfUninitializedData
        UInt32 AddressOfEntryPoint
        UInt32 BaseOfCode
      }
      $IMAGE_OPTIONAL_HEADER.Magic = switch ($IMAGE_OPTIONAL_HEADER.Magic) {
        0x10B  {'PE'} 0x20B {'PE+'}
        default{throw [InvalidOperationException]::new('Unknown PE type.')}
      }
      if ($IMAGE_FILE_HEADER.Machine -eq 32) {
        Get-Block IMAGE_OPTIONAL_HEADER {UInt32 BaseOfData}
      }
      Get-Block IMAGE_OPTIONAL_HEADER {
        UIntPtr ImageBase
        UInt32  SectionAlignment
        UInt32  FileAlignment
        UInt16  MajorOperatingSystemVersion
        UInt16  MinorOperatingSystemVersion
        UInt16  MajorImageVersion
        UInt16  MinorImageVersion
        UInt16  MajorSubsystemVersion
        UInt16  MinorSubsystemVersion
        UInt32  Win32VersionValue
        UInt32  SizeOfImage
        UInt32  SizeOfHeaders
        UInt32  CheckSum
        UInt16  Subsystem
        UInt16  DllCharacteristics
        UIntPtr SizeOfStackReserve
        UIntPtr SizeOfStackCommit
        UIntPtr SizeOfHeapReserve
        UIntPtr SizeOfHeapCommit
        UInt32  LoaderFlags
        UInt32  NumberOfRvaAndSizes
      }
      Write-Verbose "Image data directories offset 0x$($fs.Position.ToString('X'))"
      $DataDirectories = (0..($IMAGE_OPTIONAL_HEADER.NumberOfRvaAndSizes - 1)).ForEach{
        [PSCustomObject]@{
          Name = $RvaAndSizes[$_]
          RVA = $br.ReadUInt32()
          Size = $br.ReadUInt32()
        }
      }
      if ($DataDir) { $DataDirectories }
      Write-Verbose "Image sections offset 0x$($fs.Position.ToString('X'))"
      $sections = (0..($IMAGE_FILE_HEADER.NumberOfSections - 1)).ForEach{
        [PSCustomObject]@{
          Name = ($$ = [String]::new($br.ReadBytes(0x08)).Trim("`0"))
          VirtualSize = $br.ReadUInt32()
          VirtualAddress = $br.ReadUInt32()
          SizeOfRawData = $br.ReadUInt32()
          PointerToRawData = $br.ReadUInt32()
          PointerToRelocations = $br.ReadUInt32()
          PointerToLinenumbers = $br.ReadUInt32()
          NumberOfRelocations = $br.ReadUInt16()
          NumberOfLinenumbers = $br.ReadUInt16()
          Characteristics = $br.ReadUInt32()
        }
        Write-Verbose "Section $$"
      }
      if ($Section) { Format-Table -InputObject $sections -AutoSize }

      if ($Exports) {
        if (!($Export = $DataDirectories.Where{$_.Name -ceq 'Export'}).RVA) {
          Write-Verbose 'No exports'
        }
        else {
          $fs.Position = Convert-RvaToRaw $Export.RVA $IMAGE_OPTIONAL_HEADER.SectionAlignment
          Write-Verbose "Image export directory offset 0x$($fs.Position.ToString('X'))"
          Get-Block IMAGE_EXPORT_DIRECTORY {
            UInt32 Characteristics
            UInt32 TimeDateStamp
            UInt16 MajorVersion
            UInt16 MinorVersion
            UInt32 Name
            UInt32 Base
            UInt32 NumberOfFunctions
            UInt32 NumberOfNames
            UInt32 AddressOfFunctions
            UInt32 AddressOfNames
            UInt32 AddressOfNameOrdinals
          }
          $fs.Position = Convert-RvaToRaw $IMAGE_EXPORT_DIRECTORY.AddressOfFunctions
          $funcs = @{}
          (0..($IMAGE_EXPORT_DIRECTORY.NumberOfFunctions - 1)).ForEach{
            $adr = $br.ReadUInt32()
            $fwd = Convert-RvaToRaw $adr $IMAGE_OPTIONAL_HEADER.FileAlignment
            $funcs[$IMAGE_EXPORT_DIRECTORY.Base + $_] = (
              ($Export.RVA -le $adr) -and ($adr -lt ($Export.RVA + $Export.Size))
            ) ? @{ Address = ''; Forward = Get-RawString $fwd -NoMove } : @{
              Address = $adr.ToString('X8'); Forward = ''
            }
          }
          $ords = Convert-RvaToRaw $IMAGE_EXPORT_DIRECTORY.AddressOfNameOrdinals
          $fs.Position = Convert-RvaToRaw $IMAGE_EXPORT_DIRECTORY.AddressOfNames
          (0..($IMAGE_EXPORT_DIRECTORY.NumberOfNames - 1)).ForEach{
            $cursor = $fs.Position
            $fs.Position = $ords
            $ord = $br.ReadUInt16() + $IMAGE_EXPORT_DIRECTORY.Base
            $ords = $fs.Position
            $fs.Position = $cursor

            [PSCustomObject]@{
              Ordinal = $ord
              Address = $funcs.$ord.Address
              Name = Get-RawString (Convert-RvaToRaw ($br.ReadUInt32())) -NoMove
              ForwardedTo = $funcs.$ord.Forward
            }
          }
        }
      }

      if ($Imports) {
        if (!($Import = $DataDirectories.Where{$_.Name -ceq 'Import'}).RVA) {
          Write-Verbose 'No imports'
        }
        else {
          $fs.Position = Convert-RvaToRaw $Import.RVA $IMAGE_OPTIONAL_HEADER.SectionAlignment
          Write-Verbose "Image import descriptor offset 0x$($fs.Position.ToString('X'))"
          (0..($Import.Size / 0x14 - 2)).ForEach{
            Get-Block IMAGE_IMPORT_DESCRIPTOR {
              UInt32 Characteristics
              UInt32 TimeDateStamp
              UInt32 ForwarderChain
              UInt32 Name
              UInt32 FirstThunk
            }
            $dll = Get-RawString (Convert-RvaToRaw $IMAGE_IMPORT_DESCRIPTOR.Name) -NoMove

            $cursor = $fs.Position
            $thunk = Convert-RvaToRaw $IMAGE_IMPORT_DESCRIPTOR.FirstThunk

            while (1) {
              $fs.Position = $thunk
              Get-Block IMAGE_THUNK_DATA {
                UIntPtr AddressOfData
              }

              if (!$IMAGE_THUNK_DATA.AddressOfData -or $IMAGE_THUNK_DATA.AddressOfData -gt [UInt32]::MaxValue) { break }
              $thunk = $fs.Position
              $fs.Position = Convert-RvaToRaw $IMAGE_THUNK_DATA.AddressOfData
              [PSCustomObject]@{
                Module = $dll
                Ordinal = $br.ReadUInt16().ToString('X')
                Name = Get-RawString $fs.Position
              }
              $IMAGE_THUNK_DATA = @{}
            }

            $fs.Position = $cursor
            $IMAGE_IMPORT_DESCRIPTOR = @{}
          }
        }
      }
    }
    catch { Write-Verbose $_ }
    finally {
      ($br, $fs).ForEach{ if ($_) { $_.Dispose() } }
    }
  }
}
