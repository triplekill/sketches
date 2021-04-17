. .\tiny.ps1

New-Enum IMAGE_DOS_SIGNATURE {
  DOS    = 0x5A4D
  OS2    = 0x454E
  OS2_LE = 0x454C
  VXD    = 0x454C
} -Type ([UInt16])

New-Enum IMAGE_FILE_MACHINE {
  UNKNOWN     = 0x0000
  TARGET_HOST = 0x0001
  I386        = 0x014c
  R3000       = 0x0162
  R4000       = 0x0166
  R10000      = 0x0168
  WCEMIPSV2   = 0x0169
  ALPHA       = 0x0184
  SH3         = 0x01a2
  SH3DSP      = 0x01a3
  SH3E        = 0x01a4
  SH4         = 0x01a6
  SH5         = 0x01a8
  ARM         = 0x01c0
  THUMB       = 0x01c2
  ARMNT       = 0x01c4
  AM33        = 0x01d3
  POWERPC     = 0x01F0
  POWERPCFP   = 0x01f1
  IA64        = 0x0200
  MIPS16      = 0x0266
  ALPHA64     = 0x0284
  MIPSFPU     = 0x0366
  MIPSFPU16   = 0x0466
  AXP64       = 0x0284
  TRICORE     = 0x0520
  CEF         = 0x0CEF
  EBC         = 0x0EBC
  AMD64       = 0x8664
  M32R        = 0x9041
  ARM64       = 0xAA64
  CEE         = 0xC0EE
} -Type ([UInt16])

New-Enum IMAGE_FILE_CHARACTERISTICS {
  RELOCS_STRIPPED         = 0x0001
  EXECUTABLE_IMAGE        = 0x0002
  LINE_NUMS_STRIPPED      = 0x0004
  LOCAL_SYMS_STRIPPED     = 0x0008
  AGGRESIVE_WS_TRIM       = 0x0010
  LARGE_ADDRESS_AWARE     = 0x0020
  BYTES_REVERSED_LO       = 0x0080
  32BIT_MACHINE           = 0x0100
  DEBUG_STRIPPED          = 0x0200
  REMOVABLE_RUN_FROM_SWAP = 0x0400
  NET_RUN_FROM_SWAP       = 0x0800
  SYSTEM                  = 0x1000
  DLL                     = 0x2000
  UP_SYSTEM_ONLY          = 0x4000
  BYTES_REVERSED_HI       = 0x8000
} -Type ([UInt16]) -Flags

New-Enum IMAGE_NT_OPTIONAL_HDR_MAGIC {
  PE32 = 0x10B
  PE64 = 0x20B
} -Type ([UInt16])

New-Enum IMAGE_NT_SIGNATURE {
  Valid = 0x00004550
} -Type ([UInt32])

New-Enum IMAGE_SUBSYSTEM {
  UNKNOWN                  = 0
  NATIVE                   = 1
  WINDOWS_GUI              = 2
  WINDOWS_CUI              = 3
  OS2_CUI                  = 5
  POSIX_CUI                = 7
  NATIVE_WINDOWS           = 8
  WINDOWS_CE_GUI           = 9
  EFI_APPLICATION          = 10
  EFI_BOOT_SERVICE_DRIVER  = 11
  EFI_RUNTIME_DRIVER       = 12
  EFI_ROM                  = 13
  XBOX                     = 14
  WINDOWS_BOOT_APPLICATION = 16
  XBOX_CODE_CATALOG        = 17
} -Type ([UInt16])

New-Enum IMAGE_DLLCHARACTERISTICS {
  HIGH_ENTROPY_VA       = 0x0020
  DYNAMIC_BASE          = 0x0040
  FORCE_INTEGRITY       = 0x0080
  NX_COMPAT             = 0x0100
  NO_ISOLATION          = 0x0200
  NO_SEH                = 0x0400
  NO_BIND               = 0x0800
  APPCONTAINER          = 0x1000
  WDM_DRIVER            = 0x2000
  GUARD_CF              = 0x4000
  TERMINAL_SERVER_AWARE = 0x8000
} -Type ([UInt16]) -Flags

New-Enum IMAGE_DIRECTORY_ENTRY {
  EXPORT         = 0
  IMPORT         = 1
  RESOURCE       = 2
  EXCEPTION      = 3
  SECURITY       = 4
  BASERELOC      = 5
  DEBUG          = 6
  ARCHITECTURE   = 7
  GLOBALPTR      = 8
  TLS            = 9
  LOAD_CONFIG    = 10
  BOUND_IMPORT   = 11
  IAT            = 12
  DELAY_IMPORT   = 13
  COM_DESCRIPTOR = 14
  RESERVED       = 15
} -Type ([UInt32])

New-Enum IMAGE_SCN {
  TYPE_NO_PAD            = 0x00000008
  CNT_CODE               = 0x00000020
  CNT_INITIALIZED_DATA   = 0x00000040
  CNT_UNINITIALIZED_DATA = 0x00000080
  LNK_OTHER              = 0x00000100
  LNK_INFO               = 0x00000200
  LNK_REMOVE             = 0x00000800
  LNK_COMDAT             = 0x00001000
  NO_DEFER_SPEC_EXC      = 0x00004000
  GPREL                  = 0x00008000
  MEM_FARDATA            = 0x00008000
  MEM_PURGEABLE          = 0x00020000
  MEM_16BIT              = 0x00020000
  MEM_LOCKED             = 0x00040000
  MEM_PRELOAD            = 0x00080000
  ALIGN_1BYTES           = 0x00100000
  ALIGN_2BYTES           = 0x00200000
  ALIGN_4BYTES           = 0x00300000
  ALIGN_8BYTES           = 0x00400000
  ALIGN_16BYTES          = 0x00500000
  ALIGN_32BYTES          = 0x00600000
  ALIGN_64BYTES          = 0x00700000
  ALIGN_128BYTES         = 0x00800000
  ALIGN_256BYTES         = 0x00900000
  ALIGN_512BYTES         = 0x00A00000
  ALIGN_1024BYTES        = 0x00B00000
  ALIGN_2048BYTES        = 0x00C00000
  ALIGN_4096BYTES        = 0x00D00000
  ALIGN_8192BYTES        = 0x00E00000
  ALIGN_MASK             = 0x00F00000
  LNK_NRELOC_OVFL        = 0x01000000
  MEM_DISCARDABLE        = 0x02000000
  MEM_NOT_CACHED         = 0x04000000
  MEM_NOT_PAGED          = 0x08000000
  MEM_SHARED             = 0x10000000
  MEM_EXECUTE            = 0x20000000
  MEM_READ               = 0x40000000
  MEM_WRITE              = 0x80000000
} -Type ([UInt32]) -Flags

New-Structure IMAGE_DOS_HEADER {
  IMAGE_DOS_SIGNATURE e_magic
  UInt16   e_cblp
  UInt16   e_cp
  UInt16   e_crlc
  UInt16   e_cparhdr
  UInt16   e_minalloc
  UInt16   e_maxalloc
  UInt16   e_ss
  UInt16   e_sp
  UInt16   e_csum
  UInt16   e_ip
  UInt16   e_cs
  UInt16   e_lfarlc
  UInt16   e_ovno
  UInt16[] 'e_res ByValArray 4'
  UInt16   e_oemid
  UInt16   e_oeminfo
  UInt16[] 'e_res2 ByValArray 10'
  Int32    e_lfanew
}

New-Structure IMAGE_FILE_HEADER {
  IMAGE_FILE_MACHINE Machine
  UInt16 NumberOfSections
  UInt32 TimeDateStamp
  UInt32 PointerToSymbolTable
  UInt32 NumberOfSymbols
  UInt16 SizeOfOptionalHeader
  IMAGE_FILE_CHARACTERISTICS Characteristics
}

New-Structure IMAGE_DATA_DIRECTORY {
  UInt32 VirtualAddress
  UInt32 Size
}

New-Structure IMAGE_OPTIONAL_HEADER32 {
  IMAGE_NT_OPTIONAL_HDR_MAGIC Magic
  Byte   MajorLinkerVersion
  Byte   MinorLinkerVersion
  UInt32 SizeOfCode
  UInt32 SizeOfInitializedData
  UInt32 SizeOfUninitializedData
  UInt32 AddressOfEntryPoint
  UInt32 BaseOfCode
  UInt32 BaseOfData
  UInt32 ImageBase
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
  IMAGE_SUBSYSTEM Subsystem
  IMAGE_DLLCHARACTERISTICS DllCharacteristics
  UInt32 SizeOfStackReserve
  UInt32 SizeOfStackCommit
  UInt32 SizeOfHeapReserve
  UInt32 SizeOfHeapCommit
  UInt32 LoaderFlags
  UInt32 NumberOfRvaAndSizes
  IMAGE_DATA_DIRECTORY[] 'DataDirectory ByValArray 16'
}

New-Structure IMAGE_OPTIONAL_HEADER64 {
  IMAGE_NT_OPTIONAL_HDR_MAGIC Magic
  Byte   MajorLinkerVersion
  Byte   MinorLinkerVersion
  UInt32 SizeOfCode
  UInt32 SizeOfInitializedData
  UInt32 SizeOfUninitializedData
  UInt32 AddressOfEntryPoint
  UInt32 BaseOfCode
  UInt64 ImageBase
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
  IMAGE_SUBSYSTEM Subsystem
  IMAGE_DLLCHARACTERISTICS DllCharacteristics
  UInt64 SizeOfStackReserve
  UInt64 SizeOfStackCommit
  UInt64 SizeOfHeapReserve
  UInt64 SizeOfHeapCommit
  UInt32 LoaderFlags
  UInt32 NumberOfRvaAndSizes
  IMAGE_DATA_DIRECTORY[] 'DataDirectory ByValArray 16'
}

New-Structure IMAGE_NT_HEADERS32 {
  IMAGE_NT_SIGNATURE Signature
  IMAGE_FILE_HEADER FileHeader
  IMAGE_OPTIONAL_HEADER32 OptionalHeader
}

New-Structure IMAGE_NT_HEADERS64 {
  IMAGE_NT_SIGNATURE Signature
  IMAGE_FILE_HEADER FileHeader
  IMAGE_OPTIONAL_HEADER64 OptionalHeader
}

New-Structure IMAGE_SECTION_HEADER {
  Char[] 'Name ByValArray 8'
  UInt32 Misc
  UInt32 VirtualAddress
  UInt32 SizeOfRawData
  UInt32 PointerToRawData
  UInt32 PointerToRelocations
  UInt32 PointerToLinenumbers
  UInt16 NumberOfRelocations
  UInt16 NumberOfLinenumbers
  IMAGE_SCN Characteristics
}

New-Structure IMAGE_EXPORT_DIRECTORY {
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

New-Structure IMAGE_IMPORT_BY_NAME {
  UInt16 Hint
  Char   Name
}

New-Structure IMAGE_THUNK_DATA32 {
  UInt32 AddressOfData
}

New-Structure IMAGE_THUNK_DATA64 {
  UInt64 AddressOfData
}

New-Structure IMAGE_IMPORT_DESCRIPTOR {
  UInt32 OriginalFirstThunk
  UInt32 TimeDateStamp
  UInt32 ForwarderChain
  UInt32 Name
  UInt32 FirstThunk
}

New-Structure IMAGE_BOUND_IMPORT_DESCRIPTOR {
  UInt32 TimeDateStamp
  UInt16 OffsetModuleName
  UInt16 NumberOfModuleForwarderRefs
  # IMAGE_BOUND_FORWARDER_REF[]
}

New-Structure IMAGE_BOUND_FORWARDER_REF {
  UInt32 TimeDateStamp
  UInt16 OffsetModuleName
  UInt16 Reserved
}

New-Structure IMAGE_DELAYLOAD_DESCRIPTOR {
  UInt32 Attributes
  UInt32 DllNameRVA
  UInt32 ModuleHandleRVA
  UInt32 ImportAddressTableRVA
  UInt32 ImportNameTableRVA
  UInt32 BoundImportAddressTableRVA
  UInt32 UnloadInformationTableRVA
  UInt32 TimeDateStamp
}

New-Structure IMAGE_RESOURCE_DIRECTORY {
  UInt32 Characteristics
  UInt32 TimeDateStamp
  UInt16 MajorVersion
  UInt16 MinorVersion
  UInt16 NumberOfNamedEntries
  UInt16 NumberOfIdEntries
  # IMAGE_RESOURCE_DIRECTORY_ENTRY[]
}

<# decoding some imports names (ApiSet v6)
New-Structure API_SET_NAMESPACE {
  UInt32 Version
  UInt32 Size
  UInt32 Flags
  UInt32 Count
  UInt32 EntryOffset
  UInt32 HashOffset
  UInt32 HashFactor
}

New-Structure API_SET_NAMESPACE_SET {
  UInt32 Flags
  UInt32 NameOffset
  UInt32 NameLength
  UInt32 HashedLength
  UInt32 ValueOffset
  UInt32 ValueCount
}

New-Structure API_SET_VALUE_ENTRY {
  UInt32 Flags
  UInt32 NameOffset
  UInt32 NameLength
  UInt32 ValueOffset
  UInt32 ValueLength
}#>
