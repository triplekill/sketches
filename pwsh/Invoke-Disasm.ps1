#requires -version 7
using namespace System.Reflection
using namespace System.Reflection.Emit
using namespace System.Linq.Expressions
using namespace System.Management.Automation
using namespace System.Runtime.InteropServices

$keys, $types = ($x = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys, @{
  buf   = [Byte[]]
  ptr   = [IntPtr]
  int_  = [Int32].MakeByRefType()
  ptr_  = [IntPtr].MakeByRefType()
  uint_ = [UInt32].MakeByRefType()
}
$types.Keys.ForEach{ if ($_ -notin $keys) { $x::Add($_, $types.$_) } }

function New-Delegate {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Module,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({![String]::IsNullOrEmpty($_)})]
    [ScriptBlock]$Signature
  )

  begin {
    $kernel32 = @{}
    [Array]::Find((
      Add-Type -AssemblyName Microsoft.Win32.SystemEvents -PassThru
    ), [Predicate[Type]]{$args[0].Name -eq 'kernel32'}
    ).GetMethods([BindingFlags]'NonPublic, Static, Public').Where{
      $_.Name -match '\AGet(P|M)'
    }.ForEach{ $kernel32[$_.Name] = $_ }

    if (($mod = $kernel32.GetModuleHandle.Invoke($null, @($Module))) -eq [IntPtr]::Zero) {
      throw [DllNotFoundException]::new("Cannot find $Module library.")
    }
  }
  process {}
  end {
    $funcs = @{}
    for ($i, $m, $fn, $p = 0, ([Expression].Assembly.GetType(
      'System.Linq.Expressions.Compiler.DelegateHelpers'
      ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
      ), [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr])),
      $Signature.Ast.FindAll({$args[0].CommandElements}, $true).ToArray();
      $i -lt $p.Length; $i++
    ) {
      $fnret, $fname = ($def = $p[$i].CommandElements).Value

      if ((
        $fnsig = $kernel32.GetProcAddress.Invoke($null, @($mod, $fname))
      ) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = ((
        ($fnargs -replace '\[|\]' -split ',\s+?') + $fnret
      ), $fnret)[[String]::IsNullOrEmpty($fnargs)]

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }
    Set-Variable -Name $Module -Value $funcs -Scope Script -Force
  }
}

function Get-PwshModuleBuilder {
  end {
    if (!($pmb = $ExecutionContext.SessionState.PSVariable.Get(
      'PwshModuleBuilder'
    ).Value)) {
      Set-Variable -Name PwshModuleBuilder -Value ($pmb =
        ([AssemblyBuilder]::DefineDynamicAssembly(
          ([AssemblyName]::new('PwshModuleBuilder')), 'Run'
        )).DefineDynamicModule('PwshModuleBuilder', $false)
      ) -Option Constant -Scope Global -Visibility Private
      $pmb
    } else { $pmb }
  }
}

function New-Structure {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({![String]::IsNullOrEmpty($_)})]
    [ScriptBlock]$Definition,

    [Parameter()]
    [ValidateSet(
      'Unspecified', 'Size1', 'Size2', 'Size4', 'Size8', 'Size16', 'Size32', 'Size64', 'Size128'
    )]
    [ValidateNotNullOrEmpty()]
    [PackingSize]$PackingSize = 'Unspecified',

    [Parameter()]
    [ValidateSet('Ansi', 'Auto', 'Unicode')]
    [ValidateNotNullOrEmpty()]
    [CharSet]$CharSet = 'Ansi',

    [Parameter()]
    [Switch]$Explicit
  )

  begin {
    [TypeAttributes]$attr = 'BeforeFieldInit, Class, Public, Sealed'
    $attr = $attr -bor ($Explicit.IsPresent ? 'Explicit' : 'Sequential') -bor "$($CharSet)Class"
  }
  process {}
  end {
    if (!($pmb = Get-PwshModuleBuilder).GetType($Name)) {
      $type = $pmb.DefineType($Name, $attr, [ValueType], $PackingSize)
      $ctor = [MarshalAsAttribute].GetConstructor(
        [BindingFlags]'Instance, Public', $null, [Type[]]@([UnmanagedType]), $null
      )
      $sc = @([MarshalAsAttribute].GetField('SizeConst'))

      $Definition.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
        $ftype, $fdesc = $_.CommandElements.Value
        $ftype = $pmb.GetType($Name) ?? [Type]$ftype
        $fdesc = @(($fdesc -split '\s+?').Where{$_}) # field, params ...
        switch ($fdesc.Length) {
          1 { [void]$type.DefineField($fdesc[0], $ftype, 'Public') }
          2 { .({$unm = [UnmanagedType]$fdesc[1]
              [void]$type.DefineField($fdesc[0], $ftype, 'Public, HasFieldMarshal'
              ).SetCustomAttribute([CustomAttributeBuilder]::new($ctor, [Object]@($unm)))
            },{
              [void]$type.DefineField($fdesc[0], $ftype, 'Public').SetOffset([Int32]$fdesc[1])
            })[$Explicit.IsPresent]
          }
          3 {
            $unm = [UnmanagedType]$fdesc[1]
            [void]$type.DefineField($fdesc[0], $ftype, 'Public, HasFieldMarshal'
            ).SetCustomAttribute(
              [CustomAttributeBuilder]::new($ctor, $unm, $sc, @([Int32]$fdesc[2]))
            )
          }
        } # switch
      }
      $il = $type.DefineMethod('GetSize', 'Public, Static', [Int32], [Type[]]@()).GetILGenerator()
      $il.Emit([OpCodes]::ldtoken, $type)
      $il.Emit([OpCodes]::call, [Type].GetMethod('GetTypeFromHandle'))
      $il.Emit([OpCodes]::call, [Marshal].GetMethod('SizeOf', [Type[]]@([Type])))
      $il.Emit([OpCodes]::ret)
      $il = $type.DefineMethod(
        'op_Implicit', 'PrivateScope, Public, Static, HideBySig, SpecialName',
        $type, [Type[]]@([IntPtr])
      ).GetILGenerator()
      $il.Emit([OpCodes]::ldarg_0)
      $il.Emit([OpCodes]::ldtoken, $type)
      $il.Emit([OpCodes]::call, [Type].GetMethod('GetTypeFromHandle'))
      $il.Emit([OpCodes]::call, [Marshal].GetMethod('PtrToStructure', [Type[]]@([IntPtr], [Type])))
      $il.Emit([OpCodes]::unbox_any, $type)
      $il.Emit([OpCodes]::ret)
      [void]$type.CreateType()
    }
  }
}

New-Structure cs_insn {
  UInt32 'id'
  UInt64 'address'
  UInt16 'size'
  Byte[] 'bytes ByValArray 24'
  String 'mnemonic ByValTStr 32'
  String 'op_str ByValTStr 160'
  IntPtr 'detail'
}

function Invoke-Disasm {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Alias('b')]
    [Byte[]]$Bytes,

    [Parameter()]
    [ValidateSet(
      'ARM', 'ARM64', 'MIPS', 'X86', 'PPC', 'SPARC', 'SYSZ', 'XCORE',
      'M68K', 'TMS320C64X','M680X', 'EVM', 'MOS65XX', 'MAX', 'ALL'
    )]
    [ValidateNotNullOrEmpty()]
    [Alias('ar', 'arch')]
    [String]$Architecture = 'X86',

    [Parameter()]
    [ValidateSet(
      'LITTLE_ENDIAN', 'ARM', '16', '32', '64','THUMB', 'MCLASS', 'V8',
      'MICRO', 'MIPS3','MIPS32R6', 'MIPS2', 'V9', 'QPX', 'M68K_000',
      'M68K_010', 'M68K_020', 'M68K_030', 'M68K_040', 'M68K_060',
      'BIG_ENDIAN', 'MIPS32', 'MIPS64', 'M680X_6301', 'M680X_6309',
      'M680X_6800', 'M680X_6801', 'M680X_6805', 'M680X_6808',
      'M680X_6809', 'M680X_6811', 'M680X_CPU12', 'M680X_HCS08'
      )]
    [ValidateNotNullOrEmpty()]
    [Alias('m')]
    [String]$Mode = '64',

    [Parameter()]
    [ValidateSet('Intel', 'ATT')]
    [ValidateNotNullOrEmpty()]
    [Alias('s')]
    [String]$Syntax = 'Intel',

    [Parameter()]
    [Alias('a')]
    [UInt32]$Address, # 0 by default

    [Parameter()]
    [Switch]$Version
  )

  begin {
    New-Delegate kernel32 -Signature {
      ptr  LoadLibraryW([buf])
      bool FreeLibrary([ptr])
    }

    $capstonedll = $kernel32.LoadLibraryW.Invoke(
      [Text.Encoding]::Unicode.GetBytes("$PSScriptRoot\capstone.dll")
    )

    New-Delegate capstone -Signature {
      Int32  cs_close([ptr_])
      UInt32 cs_disasm([ptr, buf, uint, ulong, uint, ptr_])
      Void   cs_free([ptr, uint])
      Int32  cs_open([int, int, ptr_])
      Int32  cs_option([ptr, int, uint])
      UInt32 cs_version([int_, int_])
    }

    $cs_err = @(
       'CS_ERR_OK', 'CS_ERR_MEM', 'CS_ERR_ARCH', 'CS_ERR_HANDLE', 'CS_ERR_CSH',
       'CS_ERR_MODE', 'CS_ERR_OPTION', 'CS_ERR_DETAIL', 'CS_ERR_MEMSETUP',
       'CS_ERR_VERSION', 'CS_ERR_DIET', 'CS_ERR_SKIPDATA', 'CS_ERR_X86_ATT',
       'CS_ERR_X86_INTEL', 'CS_ERR_X86_MASM'
    )

    $cs_mode = (
      ('LITTLE_ENDIAN', 'ARM'), # 0
      ('16', 'M68K_000', 'M680X_6301'), # 1
      ('32', 'M68K_010', 'MIPS32', 'M680X_6309'), # 2
      ('64', 'M68K_020', 'MIPS64', 'M680X_6800'), # 3
      ('THUMB', 'MICRO','V9', 'QPX', 'M68K_030', 'M680X_6801'), # 4
      ('MCLASS', 'MIPS3', 'M68K_040', 'M680X_6805'), # 5
      ('V8', 'MIPS32R6', 'M68K_060', 'M680X_6808'), # 6
      ('MIPS2', 'M680X_6809'), # 7
      ('M680X_6811'), # 8
      ('M680X_CPU12'), # 9
      ('M680X_HCS08') # 10
    ) + ,$null * 20 + ('BIG_ENDIAN')

    $cs_arch = $MyInvocation.MyCommand.Parameters.Architecture.Attributes.Where{
      $_.TypeId -eq [ValidateSetAttribute] # ghostly enum
    }.ValidValues.IndexOf($Architecture)
    $cs_mode = [Array]::FindIndex($cs_mode, [Predicate[Object]]{$Mode -in $args[0]})
  }
  process {}
  end {
    .({ # disassembly logic
      try {
        $hndl = [IntPtr]::Zero
        if (($e = $capstone.cs_open.Invoke(
          $cs_arch, ($cs_mode -ne 0 ? 1 -shl $cs_mode : 0), [ref]$hndl
        )) -ne 0) {
          throw [InvalidOperationException]::new($cs_err[$e])
        }
        # setting additional options
        if (($e = $capstone.cs_option.Invoke(
          $hndl, 1, ($Syntax -eq 'Intel' ? 1 : 0))
        ) -ne 0) {
          throw [InvalidOperationException]::new($cs_err[$e])
        }
        # disassembling
        $hdis = [IntPtr]::Zero
        if (($count = $capstone.cs_disasm.Invoke(
          $hndl, $Bytes, $bytes.Length, $Address, 0, [ref]$hdis
        )) -eq 0) {
          throw [InvalidOperationException]::('Disassembly failed')
        }
        # walking around
        $tmp = $hdis."ToInt$([IntPtr]::Size * 8)"()
        for ($i = 0; $i -lt $count; $i++) {
          Select-Object -InputObject (([IntPtr]$tmp) -as [cs_insn]) -Property mnemonic, op_str
          $tmp += [cs_insn]::GetSize()
        }
      }
      catch { Write-Verbose $_ }
      finally {
        if ($hdis -and $hdis -ne [IntPtr]::Zero) {
          $capstone.cs_free.Invoke($hdis, $count) # void
        }

        if ($hndl -and $hndl -ne [IntPtr]::Zero) {
          if (($e = $capstone.cs_close.Invoke([ref]$hndl)) -ne 0) {
            Write-Verbose "$($cs_err[$e]): release failed"
          }
        }
      }
    },{ # only show current version of capstone
      $major, $minor = 0, 0
      [void]$capstone.cs_version.Invoke([ref]$major, [ref]$minor)
      'Capstone Disassembler Engine v{0}.{1}' -f $major, $minor
    })[$Version.IsPresent]

    if ($capstonedll -and $capstonedll -ne [IntPtr]::Zero) {
      if (!$kernel32.FreeLibrary.Invoke($capstonedll)) {
        Write-Verbose 'Cannot release capstone.dll library.'
      }
    }
  }
}
