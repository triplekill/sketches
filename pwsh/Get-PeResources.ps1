using namespace System.IO
using namespace System.Text

function Get-PeResources {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateScript({!!($script:file = Convert-Path -Path $_ -ErrorAction 0)})]
    [ValidateNotNullOrEmpty()]
    [String]$Path
  )

  begin {
    $Path, $ResourceType = $file, ('???_0', 'CURSOR', 'BITMAP', 'ICON', 'MENU', 'DIALOG',
    'STRING', 'FONTDIR', 'FONT', 'ACCELERATORS', 'RCDATA', 'MESSAGETBALE', 'GROUP_CURSOR',
    '???_13', 'GROUP_ICON', '???_15', 'VERSION', 'DLGINCLUDE', '???_18', 'PLUGPLAY', 'VXD',
    'ANICURSOR', 'ANICON', 'HTML', 'MANIFEST')
    function private:Convert-RvaToRaw([UInt32]$rva, [UInt32]$align) {
      end {
        [ScriptBlock]$Aligner = {
          param([UInt32]$size)
          ($size -band ($align - 1)) ? (($size -band ($align * -1)) + $align) : $size
        }

        $sections.ForEach{
          if (($rva -ge $_.VirtualAddress) -and (
            $rva -lt ($_.VirtualAddress + (& $Aligner $_.VirtualSize))
          )) { return ($rva - ($_.VirtualAddress - $_.PointerToRawData)) }
        }
      }
    }
  }
  #process {}
  end {
    try {
      $br = [BinaryReader]::new(($fs = [File]::OpenRead($Path)))
      if ($br.ReadUInt16() -ne 0x5A4D) {
        throw [InvalidOperationException]::new('DOS signature has not been found.')
      }
      $fs.Position = 0x3C # e_lfanew
      $fs.Position = $br.ReadUInt32() # move to IMAGE_NT_HEADERS
      if ($br.ReadUInt32() -ne 0x4550) {
        throw [InvalidOperationException]::new('PE signature has not been found.')
      }
      $fs.Position += 0x02 # IMAGE_FILE_HEADER->Machine
      $NumberOfSections = $br.ReadUInt16()
      $fs.Position += 0x0C # IMAGE_FILE_HEADER->... till SizeOfOptionalHeader
      $SizeOfOptionalHeader, $offset = $br.ReadUInt16(), ($fs.Position + 0x02)
      $fs.Position += 0x26 # getting FileAlignment
      $FileAlignment = $br.ReadUInt32()
      $fs.Position = $offset + $SizeOfOptionalHeader
      if (!($PointerToRawData = ($sections = (1..$NumberOfSections).ForEach{
        [PSCustomObject]@{
          Name = [String]::new($br.ReadChars(0x08)).Trim("`0")
          VirtualSize = $br.ReadUInt32()
          VirtualAddress = $br.ReadUInt32()
          SizeOfRawData = $br.ReadUInt32()
          PointerToRawData = $br.ReadUInt32()
        }
        $fs.Position += 0x10 # move to the next section
      }).Where{$_.Name -eq '.rsrc'}.PointerToRawData)) {
        throw [InvalidOperationException]::new('It seems there are no resources.')
      }
      $fs.Position = $PointerToRawData + 0x0C # enumerate resources
      $entry = {
        param([UInt16]$name, [UInt16]$id, [Boolean]$top)
        end {
          (1..($name + $id)).ForEach{
            [PSCustomObject]@{
              Name = ($$ = $br.ReadUInt32()) -band 0x80000000 ? $(
                $cursor = $fs.Position
                $fs.Position = $PointerToRawData + ($$ -band 0x7FFFFFFF)
                [Encoding]::Unicode.GetString($br.ReadBytes($br.ReadUInt16() * 2))
                $fs.Position = $cursor
              ) : $($top ? $ResourceType[$$] : $$)
              OffsetToData = $PointerToRawData + ($br.ReadUInt32() -band 0x7FFFFFFF)
            }
          }
        }
      }
      $fmt = "$(,([Char]32)*2){0,-23} (LangID:0x{1:X}, RVA:{2:X8}, Offset:{3:X8}, Size:0x{4:X})"
      (& $entry $br.ReadUInt16() $br.ReadUInt16() $true).ForEach{
        $_.Name
        $cursor = $fs.Position
        $fs.Position = $_.OffsetToData + 0x0C
        (& $entry $br.ReadUInt16() $br.ReadUInt16()).ForEach{
          $back = $fs.Position
          $fs.Position = $_.OffsetToData + 0x10
          $LangID = $br.ReadUInt32()
          $fs.Position = $PointerToRawData + $br.ReadUInt32() # IMAGE_RESOURCE_DATA_ENTRY
          $fmt -f $_.Name, $LangID, ($$ = $br.ReadUInt32()), (
            Convert-RvaToRaw $$ $FileAlignment
          ), $br.ReadUInt32()
          $fs.Position = $back
        }
        $fs.Position = $cursor
      }
    }
    catch { Write-Verbose $_ }
    finally {
      ($br, $fs).ForEach{ if ($_) { $_.Dispose() } }
    }
  }
}
