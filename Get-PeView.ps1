using namespace System.IO

function Get-PeView {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateScript({!!($script:file = Convert-Path $_ -ErrorAction 0)})]
    [ValidateNotNullOrEmpty()]
    [String]$Path,

    [Parameter()][Alias('h')][Switch]$Headers,
    [Parameter()][Alias('e')][Switch]$Exports,
    [Parameter()][Alias('i')][Switch]$Imports
  )

  begin {
    $Path, $Machine, $FileChar, $Subsystem, $DllChar, $RvaAndSizes, $SecChar = $file, @{
      UNKNOWN = 0x000; TARGET_HOST = 0x0001; I386 = 0x014C; R3000 = 0x0162; R4000 = 0x0166; R10000 = 0x0168;
      WCEMIPSV2 = 0x0169; ALPHA = 0x0184; SH3 = 0x01A2; SH3DSP = 0x01A3; SH3E = 0x01A4; SH4 = 0x01A6;
      SH5 = 0x01A8; ARM = 0x01C0; THUMB = 0x01C2; ARMNT = 0x01C4; AM33 = 0x01D3; POWERPC = 0x01F0;
      POWERPCFP = 0x01F1; IA64 = 0x0200; MIPS16 = 0x0266; ALPHA64 = 0x0284; MIPSFPU = 0x0366;
      MIPSFPU16 = 0x0466; AXP64 = 0x0284; TRICORE = 0x0520; CEF = 0x0CEF; EBC = 0x0EBC; AMD64 = 0x8664;
      M32R = 0x9041; ARM64 = 0xAA64; CEE = 0xC0EE
    }, @{
      RELOCS_STRIPPED = 0x0001; EXECUTABLE_IMAGE = 0x0002; LINE_NUMS_STRIPPED = 0x0004;
      LOCAL_SYMS_STRIPPED = 0x0008; AGGRESIVE_WS_TRIM = 0x0010; LARGE_ADDRESS_AWARE = 0x0020;
      BYTES_REVERSED_LO = 0x0080; '32BIT_MACHINE' = 0x0100; DEBUG_STRIPPED = 0x0200;
      REMOVABLE_RUN_FROM_SWAP = 0x0400; NET_RUN_FROM_SWAP = 0x0800; SYSTEM = 0x1000; DLL = 0x2000;
      UP_SYSTEM_ONLY = 0x4000; BYTES_REVERSED_HI = 0x8000
    }, @{
      UNKNOWN = 0; NATIVE = 1; WINDOWS_GUI = 2; WINDOWS_CUI = 3; OS2_CUI = 5; POSIX_CUI = 7;
      NATIVE_WINDOWS = 8; WINDOWS_CE_GUI = 9; EFI_APPLICATION = 10; EFI_BOOT_SERVICE_DRIVER = 11;
      EFI_RUNTIME_DRIVER = 12; EFI_ROM = 13; XBOX = 14; WINDOWS_BOOT_APPLICATION = 16;
      XBOX_CODE_CATALOG = 17
    }, @{
      HIGH_ENTROPY_VA = 0x0020; DYNAMIC_BASE = 0x0040; FORCE_INTEGRITY = 0x0080; NX_COMPAT = 0x0100;
      NO_ISOLATION = 0x0200; NO_SEH = 0x0400; NO_BIND = 0x0800; APPCONTAINER = 0x1000; WDM_DRIVER = 0x2000;
      GUARD_CF = 0x4000; TERMINAL_SERVER_AWARE = 0x8000
    }, @(
      'Export', 'Import', 'Resource', 'Exception', 'Certificates', 'BaseRelocation', 'Debug', 'Architecture',
      'GlobalPointer', 'ThreadStorage', 'LoadConfiguration', 'BoundImport', 'ImportAddressTable', 'DelayImport',
      'ComDescriptor', 'Reserved'
    ), @{
      TYPE_NO_PAD = 0x00000008; CNT_CODE = 0x00000020; CNT_INITIALIZED_DATA = 0x00000040;
      CNT_UNINITIALIZED_DATA = 0x00000080; LNK_OTHER = 0x00000100; LNK_INFO = 0x00000200;
      LNK_REMOVE = 0x00000800; LNK_COMDAT = 0x00001000; NO_DEFER_SPEC_EXC = 0x00004000; GPREL = 0x00008000;
      MEM_FARDATA = 0x00008000; MEM_PURGEABLE = 0x00020000; MEM_16BIT = 0x00020000; MEM_LOCKED = 0x00040000;
      MEM_PRELOAD = 0x00080000; ALIGN_1BYTES = 0x00100000; ALIGN_2BYTES = 0x00200000; ALIGN_4BYTES = 0x00300000;
      ALIGN_8BYTES = 0x00400000; ALIGN_16BYTES = 0x00500000; ALIGN_32BYTES = 0x00600000; ALIGN_64BYTES = 0x00700000;
      ALIGN_128BYTES = 0x00800000; ALIGN_256BYTES = 0x00900000; ALIGN_512BYTES = 0x00A00000;
      ALIGN_1024BYTES = 0x00B00000; ALIGN_2048BYTES = 0x00C00000; ALIGN_4096BYTES = 0x00D00000;
      ALIGN_8192BYTES = 0x00E00000; ALIGN_MASK = 0x00F00000; LNK_NRELOC_OVFL = 0x01000000;
      MEM_DISCARDABLE = 0x02000000; MEM_NOT_CACHED = 0x04000000; MEM_NOT_PAGED = 0x08000000; MEM_SHARED = 0x10000000;
      MEM_EXECUTE = 0x20000000; MEM_READ = 0x40000000; MEM_WRITE = [BitConverter]::ToUInt32(
        [BitConverter]::GetBytes(0x80000000), 0
      )
    }

    function private:Get-Block([String]$Name, [ScriptBlock]$Fields, [Boolean]$Print) {
      end {
        if (!($var = $ExecutionContext.SessionState.PSVariable.Get($Name)).Value) {
          $var = Set-Variable -Name $Name -Value @{} -Scope Script -PassThru
        }

        $printf, $value, $bitmask = {
          param([Object[]]$params, [String]$fmt = '{0,16:X} {1}')
          Write-Host "$([String]::Format($fmt, $params))"
        }, {
          param([Hashtable]$map, [Int32]$val)
          $map.Keys.Where{$map.$_ -eq $val}
        }, {
          param([Hashtable]$map, [Int32]$val)
          $map.Keys.ForEach{if (($val -band $map.$_) -eq $map.$_) {$_}} -join "`n`t`t   "
        }
        $Fields.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
          $type, $desc, $pack = $_.CommandElements.Value
          $type = $type -creplace 'Ptr', $Bitness
          $var.Value[$desc] = $pack ? $(
            (0..($pack - 1)).ForEach{$br."Read$($type)"()}
          ) : $(
            ($$ = $br."Read$($type)"())
            if ($Print) {
              switch -regex (($remark = ($desc -creplace '(\B[A-Z])', ' $1').ToLower())) {
                '^charac' { if ($$) { & $printf ($$, $remark, (& $bitmask $FileChar $$)) "{0,16:X} {1}`n`t`t   {2}" } }
                '^dll'    { & $printf ($$, $remark, (& $bitmask $DllChar $$)) "{0,16:X} {1}`n`t`t   {2}" }
                'machine' { & $printf ($$, $remark, (& $value $Machine $$)) '{0,16:X} {1} ({2})'}
                'magic'   { & $printf ($$, $remark, ($$ -eq 0x20B ? '+' : '')) '{0,16:X} {1} # (PE32{2})'}
                'major'   { $ver = $$ }
                'minor'   { & $printf ($ver, $$, ($remark -replace 'minor ')) '{0,13}.{1:D2} {2}' }
                '^subsys' { & $printf ($$, $remark, (& $value $Subsystem $$)) '{0,16:X} {1} ({2})' }
                'time'    { & $printf ($$, $remark, ([DateTime]'1.1.1970').AddSeconds($$)) '{0,16:X} {1} ({2})'}
                default   { & $printf ($$, $remark) }
              }
            } # Print
          )
        } # Fields
      }
    }

    function private:Convert-RvaToRaw([UInt32]$Rva, [UInt32]$Align=$IMAGE_OPTIONAL_HEADER.FileAlignment) {
      end {
        [ScriptBlock]$Aligner = {
          param([UInt32]$Size) ($Size -band ($Align - 1)) ? (($Size -band ($Align * -1)) + $Align) : $Size
        }

        $sections.ForEach{
          if (($Rva -ge $_.VirtualAddress) -and ($Rva -lt ($_.VirtualAddress + (& $Aligner $_.VirtualSize)))) {
            return ($Rva - ($_.VirtualAddress - $_.PointerToRawData))
          }
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

      $fs.Position = $IMAGE_DOS_HEADER.e_lfanew
      if ($br.ReadUInt32() -ne 0x4550) {
        throw [InvalidOperationException]::new('PE signature has not begin found.')
      }
      if ($Headers) { Write-Host 'FILE HEADER VALUES' }
      Get-Block IMAGE_FILE_HEADER {
        UInt16 Machine
        UInt16 NumberOfSections
        UInt32 TimeDateStamp
        UInt32 PointerToSymbolTable
        UInt32 NumberOfSymbols
        UInt16 SizeOfOptionalHeader
        UInt16 Characteristics
      } -Print:$Headers
      $Bitness = (0x20, 0x40)[$IMAGE_FILE_HEADER.SizeOfOptionalHeader / 0x10 - 0x0E]
      if ($Headers) { Write-Host 'OPTIONAL HEADER VALUES' }
      Get-Block IMAGE_OPTIONAL_HEADER {
        UInt16 Magic
        Byte   MajorLinkerVersion
        Byte   MinorLinkerVersion
        UInt32 SizeOfCode
        UInt32 SizeOfInitializedData
        UInt32 SizeOfUninitializedData
        UInt32 AddressOfEntryPoint
        UInt32 BaseOfCode
      } -Print:$Headers
      if ($Bitness -eq 0x20) { Get-Block IMAGE_OPTIONAL_HEADER {UInt32 BaseOfData} -Print:$Headers }
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
        UInt32  Checksum
        UInt16  Subsystem
        UInt16  DllCharacteristics
        UIntPtr SizeOfStackReserve
        UIntPtr SizeOfStackCommit
        UIntPtr SizeOfHeapReserve
        UIntPtr SizeOfHeapCommit
        UInt32  LoaderFlags
        UInt32  NumberOfRvaAndSizes
      } -Print:$Headers
      $DataDirectories = (0..($IMAGE_OPTIONAL_HEADER.NumberOfRvaAndSizes - 1)).ForEach{
        ($$ = [PSCustomObject]@{
          Name = $RvaAndSizes[$_]
          RVA = $br.ReadUInt32()
          Size = $br.ReadUInt32()
        })
        if ($Headers) {
          Write-Host "$([String]::Format(
            '{0,16:X} [{1,8:X}] RVA [size] of {2} Directory',
            $$.RVA, $$.Size, ($$.Name -creplace '(\B[A-Z])', ' $1')
          ))"
        }
      }
      $Sections = (0..($IMAGE_FILE_HEADER.NumberOfSections - 1)).ForEach{
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
      }
      if ($Headers) {
        $Sections | Select-Object Name, @{N='VirtualSize';E={$_.VirtualSize.ToString('X')}}, @{
          N='VirtualAddress';E={$_.VirtualAddress.ToString('X')}
        }, @{N='SizeOfRawData';E={$_.SizeOfRawData.ToString('X')}}, @{
          N='PointerToRawData';E={$_.PointerToRawData.ToString('X')}
        }, @{N='Characteristics';E={
          foreach ($key in $SecChar.Keys) {
            if (($_.Characteristics -band $SecChar.$key) -eq $SecChar.$key) {$key}
          }
        }} | Format-Table -AutoSize
      } # Headers

      if ($Exports) {
        if (!($Export = $DataDirectories.Where{$_.Name -ceq 'Export'}).RVA) {
          Write-Verbose 'No exports'
        }
        else {
          $fs.Position = Convert-RvaToRaw $Export.RVA $IMAGE_OPTIONAL_HEADER.SectionAlignment
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
            $fwd = Convert-RvaToRaw $adr
            $funcs[$IMAGE_EXPORT_DIRECTORY.Base + $_] = (
              ($Export.RVA -le $adr) -and ($adr -lt ($Export.RVA + $Export.Size))
            ) ? @{Address = ''; Forward = Get-RawString $fwd -NoMove} : @{
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
      } # Exports

      if ($Imports) {
        if (!($Import = $DataDirectories.Where{$_.Name -ceq 'Import'}).RVA) {
          Write-Verbose 'No imports'
        }
        else {
          $fs.Position = Convert-RvaToRaw $Import.RVA $IMAGE_OPTIONAL_HEADER.SectionAlignment
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
      } # Imports
    }
    catch { Write-Verbose $_ }
    finally {
      ($br, $fs).ForEach{ if ($_) { $_.Dispose() } }
    }
  }
}
