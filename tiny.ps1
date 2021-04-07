using namespace System.Reflection
using namespace System.Reflection.Emit
using namespace System.Linq.Expressions
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
    $mod = ($ps = Get-Process -Id $PID).Modules
    $ps.Dispose()
    $jmp = [Marshal]::ReadInt32($mod[0].BaseAddress, 0x3C) + [Marshal]::SizeOf([UInt32]0)
    $jmp = switch ([BitConverter]::ToUInt16( # make sure the number is unsigned
      [BitConverter]::GetBytes([Marshal]::ReadInt16($mod[0].BaseAddress, $jmp)), 0
    )) { 0x014C {0x20, 0x78, 0x7C} 0x8664 {0x40, 0x88, 0x8C} default { throw } }
    $to_i = "ToInt$($jmp[0])"
    if (!($ib = $mod.Where{$_.ModuleName -match "^$Module"}.BaseAddress)) {
      throw [DllNotFoundException]::new("Cannot find $Module library.")
    }
    $tmp = $ib.$to_i()
    $pe, $va, $sz = [Marshal]::ReadInt32($ib, 0x3C), ($tmp + $jmp[1]), ($tmp + $jmp[2])
    $va, $sz = [Marshal]::ReadInt32([IntPtr]($pe + $va)), [Marshal]::ReadInt32([IntPtr]($pe + $sz))
    ($ed = @{bs = 0x10; nf = 0x14; nn = 0x18; af = 0x1C; an = 0x20; ao = 0x24}).Keys.ForEach{
      $val = [Marshal]::ReadInt32($ib, $va + $ed.$_)
      Set-Variable -Name $_ -Value ($_.StartsWith('a') ? $tmp + $val : $val) -Scope Script
    }

    function Assert-Forwarder([UInt32]$fa) {
      end { ($va -le $fa) -and ($fa -lt ($va + $sz)) }
    }

    $funcs = @{}
    (0..($nf - 1)).ForEach{
      $funcs[$bs + $_] = (Assert-Forwarder ($fa = [Marshal]::ReadInt32([IntPtr]($af + $_ * 4)))) ? @{
        Address = ''; Forward = [Marshal]::PtrToStringAnsi([IntPtr]($tmp + $fa))
      } : @{Address = [IntPtr]($tmp + $fa); Forward = ''}
    }
    $exports = (0..($nn - 1)).ForEach{
      [PSCustomObject]@{
        Ordinal = ($ord = $bs + [Marshal]::ReadInt16([IntPtr]($ao + $_ * 2)))
        Address = $funcs[$ord].Address
        Name = [Marshal]::PtrToStringAnsi([IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($an + $_ * 4))))
        Forward = $funcs[$ord].Forward
      }
    }
  }
  process {}
  end {
    $funcs.Clear()
    for ($i, $m, $fn, $p = 0, ([Expression].Assembly.GetType(
        'System.Linq.Expressions.Compiler.DelegateHelpers'
      ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
      ), [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr])),
      $Signature.Ast.FindAll({$args[0].CommandElements}, $true).ToArray();
      $i -lt $p.Length; $i++
    ) {
      $fnret, $fname = ($def = $p[$i].CommandElements).Value
      $fnsig, $fnarg = $exports.Where{$_.Name -ceq $fname}.Address, $def.Pipeline.Extent.Text

      if (!$fnsig) { throw [InvalidOperationException]::new("Cannot find $fname signature.") }

      [Object[]]$fnarg = [String]::IsNullOrEmpty($fnarg) ? $fnret : (
        ($fnarg -replace '\[|\]' -split ',\s+?').ForEach{
          $_.StartsWith('_') ? (Get-Variable $_.Remove(0, 1) -ValueOnly) : $_
        } + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnarg)
      ).Invoke([Marshal], $fnsig)
    }

    Set-Variable -Name $Module -Value $funcs -Scope Script
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

function New-Enum {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({![String]::IsNullOrEmpty($_)})]
    [ScriptBlock]$Definition,

    [Parameter()]
    [Type]$Type = [Int32],

    [Parameter()]
    [Switch]$Flags
  )

  end {
    if (!($pmb = Get-DynBuilder).GetType($Name)) {
      $enm = $pmb.DefineEnum($Name, 'Public', $Type)
      if ($Flags) {
        $enm.SetCustomAttribute((
          [CustomAttributeBuilder]::new([FlagsAttribute].GetConstructor(@()), @())
        ))
      }

      $i = 0
      $Definition.Ast.FindAll({$args[0].CommandElements}, $true).ToArray().ForEach{
        $fn, $$, $fv = $_.CommandElements
        $i = [BitConverter]::"To$($Type.Name)"([BitConverter]::GetBytes($fv.Value ?? $i))
        [void]$enm.DefineLiteral($fn.Value, $i)
        $i+=1
      }
      [void]$enm.CreateType()
    }
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
      $il = $type.DefineMethod('OfsOf', 'Public, Static', [Int32], [Type[]]@([String])).GetILGenerator()
      $local = $il.DeclareLocal([String])
      $il.Emit([OpCodes]::ldtoken, $type)
      $il.Emit([OpCodes]::call, [Type].GetMethod('GetTypeFromHandle'))
      $il.Emit([OpCodes]::ldarg_0)
      $il.Emit([OpCodes]::call, [Marshal].GetMethod('OffsetOf', [Type[]]([Type], [String])))
      $il.Emit([OpCodes]::stloc_0)
      $il.Emit([OpCodes]::ldloca_s, $local)
      $il.Emit([OpCodes]::call, [IntPtr].GetMethod('ToInt32', [Type[]]@()))
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

function ConvertTo-Structure {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Byte[]]$Buffer,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNull()]
    [Type]$Type
  )

  end {
    try {
      $gch = [GCHandle]::Alloc($Buffer, [GCHandleType]::Pinned)
      $gch.AddrOfPinnedObject() -as $Type
    }
    catch { Write-Verbose $_ }
    finally {
      if ($gch) { $gch.Free() }
    }
  }
}
