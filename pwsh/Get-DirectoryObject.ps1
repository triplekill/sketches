#requires -version 7

using namespace System.Reflection
using namespace System.ComponentModel
using namespace System.Reflection.Emit
using namespace System.Linq.Expressions
using namespace Microsoft.Win32.SafeHandles
using namespace System.Runtime.InteropServices

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
    ), [Predicate[Type]]{$args[0].Name -eq 'kernel32'}).GetMethods(
      [BindingFlags]'NonPublic, Static, Public'
    ).Where{$_.Name -cmatch '\AGet(P|M)'}.ForEach{$kernel32[$_.Name] = $_}

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

      if (($fnsig = $kernel32.GetProcAddress.Invoke(
        $null, @($mod, $fname)
      )) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = [String]::IsNullOrEmpty($fnargs) ? $fnret : (
                                          $fnargs -replace '\[|\]' -split ',\s+?') + $fnret
      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }
    Set-Variable -Name $Module -Value $funcs -Scope Script -Force
  }
}

function Get-DynBuilder {
  end {
    if (!($pmb = $ExecutionContext.SessionState.PSVariable.Get('PwshDynBuilder').Value)) {
      Set-Variable -Name PwshDynBuilder -Value ($pmb =
        ([AssemblyBuilder]::DefineDynamicAssembly(
          ([AssemblyName]::new('PwshDynBuilder')), 'Run'
        )).DefineDynamicModule('PwshDynBuilder', $false)
      ) -Option Constant -Scope Global -Visibility Private
      $pmb
    }
    else {$pmb}
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
    if (!($pmb = Get-DynBuilder).GetType($Name)) {
      $type = $pmb.DefineType($Name, $attr, [ValueType], $PackingSize)
      $ctor = [MarshalAsAttribute].GetConstructor(
        [BindingFlags]'Instance, Public', $null, [Type[]]([UnmanagedType]), $null
      )
      $sc = [MarshalAsAttribute].GetField('SizeConst')

      $Definition.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
        $ftype, $fdesc = $_.CommandElements.Value
        $ftype = $pmb.GetType($ftype) ?? [Type]$ftype
        $fdesc = @(($fdesc -split '\s+?').Where{$_}) # field, param ...
        switch ($fdesc.Length) {
          1 {[void]$type.DefineField($fdesc[0], $ftype, 'Public')}
          2 {
            [void]($Explicit.IsPresent ? $type.DefineField($fdesc[0], $ftype, 'Public'
            ).SetOffset([Int32]$fdesc[1]) : $type.DefineField(
              $fdesc[0], $ftype, 'Public, HasFieldMarshal'
            ).SetCustomAttribute(
              [CustomAttributeBuilder]::new($ctor, [Object]([UnmanagedType]$fdesc[1]))
            ))
          }
          3 {
            [void]$type.DefineField($fdesc[0], $ftype, 'Public, HasFieldMarshal'
            ).SetCustomAttribute(
              [CustomAttributeBuilder]::new($ctor, [UnmanagedType]$fdesc[1], $sc, ([Int32]$fdesc[2]))
            )
          }
        }
      }
      $il = $type.DefineMethod('GetSize', 'Public, Static', [Int32], [Type[]]@()).GetILGenerator()
      $il.Emit([OpCodes]::ldtoken, $type)
      $il.Emit([OpCodes]::call, [Type].GetMethod('GetTypeFromHandle'))
      $il.Emit([OpCodes]::call, [Marshal].GetMethod('SizeOf', [Type[]]([Type])))
      $il.Emit([OpCodes]::ret)
      $il = $type.DefineMethod(
        'op_Implicit', 'PrivateScope, Public, Static, HideBySig, SpecialName', $type, [Type]([IntPtr])
      ).GetILGenerator()
      $il.Emit([OpCodes]::ldarg_0)
      $il.Emit([OpCodes]::ldtoken, $type)
      $il.Emit([OpCodes]::call, [Type].GetMethod('GetTypeFromHandle'))
      $il.Emit([OpCodes]::call, [Marshal].GetMethod('PtrToStructure', [Type[]]([IntPtr], [Type])))
      $il.Emit([OpCodes]::unbox_any, $type)
      $il.Emit([OpCodes]::ret)
      [void]$type.CreateType()
    }
  }
}

######################################################################################

New-Structure UNICODE_STRING {
  UInt16 Length
  UInt16 MaximumLength
  String 'Buffer LPWstr'
} -CharSet Unicode

New-Structure OBJECT_DIRECTORY_INFORMATION {
  UNICODE_STRING Name
  UNICODE_STRING TypeName
}

New-Structure OBJECT_ATTRIBUTES {
  UInt32 Length
  IntPtr RootDirectory
  IntPtr ObjectName
  UInt32 Attributes
  IntPtr SecurityDescriptor
  IntPtr SecurityQualityOfService
}

$keys, $types = ($x = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys, @{
  ptr      = [IntPtr]
  uint_    = [UInt32].MakeByRefType()
  ustr_    = [UNICODE_STRING].MakeByRefType()
  sfh      = [SafeFileHandle]
  sfh_     = [SafeFileHandle].MakeByRefType()
  objattr_ = [OBJECT_ATTRIBUTES].MakeByRefType()
}
$types.Keys.ForEach{if ($_ -notin $keys) {$x::Add($_, $types.$_)}}

New-Delegate ntdll {
  int NtOpenDirectoryObject([sfh_, uint, objattr_])
  int NtQueryDirectoryObject([sfh, ptr, uint, bool, bool, uint_, uint_])
  int RtlNtStatusToDosError([int])
  void RtlInitUnicodeString([ustr_, ptr])
}

######################################################################################

function Get-DirectoryObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$Path
  )

  end {
    $us = [UNICODE_STRING]::new()
    try {
      $uni = [Marshal]::StringToHGlobalUni($Path)
      $ntdll.RtlInitUnicodeString.Invoke([ref]$us, $uni)

      $atr = [OBJECT_ATTRIBUTES]::new()
      $ptr = [Marshal]::AllocHGlobal($us::GetSize())
      [Marshal]::StructureToPtr($us, $ptr, $true)

      $atr.Length = $atr::GetSize()
      $atr.RootDirectory = [IntPtr]::Zero
      $atr.Attributes = 0
      $atr.ObjectName = $ptr
      $atr.SecurityDescriptor = [IntPtr]::Zero
      $atr.SecurityQualityOfService = [IntPtr]::Zero

      $sfh = [SafeFileHandle]::new([IntPtr]::Zero, $true)
      if (($nts = $ntdll.NtOpenDirectoryObject.Invoke([ref]$sfh, 0x1, [ref]$atr)) -ne 0) {
        throw [InvalidOperationException]::new([Win32Exception]::new(
          $ntdll.RtlNtStatusToDosError.Invoke($nts)
        ).Message)
      }

      $odi = [Marshal]::AllocHGlobal((
        $bsz = [OBJECT_DIRECTORY_INFORMATION]::GetSize() * [IntPtr]::Size
      ))
      $items, $bytes = [UInt32[]](,0 * 2)
      while (($nts = $ntdll.NtQueryDirectoryObject.Invoke(
        $sfh, $odi, $bsz, $false, $true, [ref]$items, [ref]$bytes
      )) -eq 0x105) {
        $odi = [Marshal]::ReAllocHGlobal($odi, [IntPtr]($bsz += $bytes))
      }

      $tmp = $odi."ToInt$([IntPtr]::Size * 8)"()
      (0..($items - 1)).ForEach{
        $itm = [IntPtr]$tmp -as [OBJECT_DIRECTORY_INFORMATION]
        [PSCustomObject]@{
          Name = $itm.Name.Buffer
          Type = $itm.TypeName.Buffer
        }
        $tmp += [OBJECT_DIRECTORY_INFORMATION]::GetSize()
      }
    }
    catch {Write-Verbose $_}
    finally {
      if ($odi) {[Marshal]::FreeHGlobal($odi)}
      if ($sfh) {$sfh.Dispose()}
      if ($ptr) {[Marshal]::FreeHGlobal($ptr)}
      if ($uni) {[Marshal]::FreeHGlobal($uni)}
    }
  }
}

#Get-DirectoryObject '\KnownDlls'
