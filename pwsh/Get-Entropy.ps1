#requires -version 6.1
using namespace System.Reflection.Emit

Set-Alias -Name ent -Value Get-Entropy
function Get-Entropy {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Byte[]]$Bytes
  )

  process {
    if (!($e = $ExecutionContext.SessionState.PSVariable.Get('PSEntropy').Value)) {
      $dm = [DynamicMethod]::new('Entropy', [Double], [Type[]]([Byte[]]))
      $il = $dm.GetILGenerator()
      # variables
      $i   = $il.DeclareLocal([Int32])
      $rng = $il.DeclareLocal([Type]::GetType('System.Int32*'))
      $pi  = $il.DeclareLocal([Type]::GetType('System.Int32*'))
      $ent = $il.DeclareLocal([Double])
      $src = $il.DeclareLocal([Double])
      # labels (four totally)
      $labels = (0..3).ForEach{ $il.DefineLabel() }
      # function body
      $il.Emit([OpCodes]::ldc_i4, 0x100)
      $il.Emit([OpCodes]::conv_u)
      $il.Emit([OpCodes]::ldc_i4_4)
      $il.Emit([OpCodes]::mul_ovf_un)
      $il.Emit([OpCodes]::localloc)
      $il.Emit([OpCodes]::stloc_1)
      $il.Emit([OpCodes]::ldloc_1)
      $il.Emit([OpCodes]::ldc_i4, 0x400)
      $il.Emit([OpCodes]::conv_i)
      $il.Emit([OpCodes]::add)
      $il.Emit([OpCodes]::stloc_2)
      $il.Emit([OpCodes]::ldc_r8, 0.0)
      $il.Emit([OpCodes]::stloc_3)
      $il.Emit([OpCodes]::ldarg_0)
      $il.Emit([OpCodes]::ldlen)
      $il.Emit([OpCodes]::conv_i4)
      $il.Emit([OpCodes]::dup)
      $il.Emit([OpCodes]::stloc_0)
      $il.Emit([OpCodes]::conv_r8)
      $il.Emit([OpCodes]::stloc_s, $src)
      $il.Emit([OpCodes]::br_s, $labels[0])
      $il.MarkLabel($labels[1]) # 0x28
      $il.Emit([OpCodes]::ldloc_1)
      $il.Emit([OpCodes]::ldarg_0)
      $il.Emit([OpCodes]::ldloc_0)
      $il.Emit([OpCodes]::ldelem_u1)
      $il.Emit([OpCodes]::conv_i)
      $il.Emit([OpCodes]::ldc_i4_4)
      $il.Emit([OpCodes]::mul)
      $il.Emit([OpCodes]::add)
      $il.Emit([OpCodes]::dup)
      $il.Emit([OpCodes]::ldind_i4)
      $il.Emit([OpCodes]::ldc_i4_1)
      $il.Emit([OpCodes]::add)
      $il.Emit([OpCodes]::stind_i4)
      $il.MarkLabel($labels[0]) # 0x35
      $il.Emit([OpCodes]::ldloc_0)
      $il.Emit([OpCodes]::ldc_i4_1)
      $il.Emit([OpCodes]::sub)
      $il.Emit([OpCodes]::dup)
      $il.Emit([OpCodes]::stloc_0)
      $il.Emit([OpCodes]::ldc_i4_0)
      $il.Emit([OpCodes]::bge_s, $labels[1])
      $il.Emit([OpCodes]::br_s, $labels[2])
      $il.MarkLabel($labels[3]) # 0x3f
      $il.Emit([OpCodes]::ldloc_2)
      $il.Emit([OpCodes]::ldind_i4)
      $il.Emit([OpCodes]::ldc_i4_0)
      $il.Emit([OpCodes]::ble_s, $labels[2])
      $il.Emit([OpCodes]::ldloc_3)
      $il.Emit([OpCodes]::ldloc_2)
      $il.Emit([OpCodes]::ldind_i4)
      $il.Emit([OpCodes]::conv_r8)
      $il.Emit([OpCodes]::ldloc_2)
      $il.Emit([OpCodes]::ldind_i4)
      $il.Emit([OpCodes]::conv_r8)
      $il.Emit([OpCodes]::ldloc_s, $src)
      $il.Emit([OpCodes]::div)
      $il.Emit([OpCodes]::ldc_r8, 2.)
      $il.Emit([OpCodes]::call, [Math].GetMethod('Log', [Type[]]([Double], [Double])))
      $il.Emit([OpCodes]::mul)
      $il.Emit([OpCodes]::add)
      $il.Emit([OpCodes]::stloc_3)
      $il.MarkLabel($labels[2]) # 0x5f
      $il.Emit([OpCodes]::ldloc_2)
      $il.Emit([OpCodes]::ldc_i4_4)
      $il.Emit([OpCodes]::conv_i)
      $il.Emit([OpCodes]::sub)
      $il.Emit([OpCodes]::dup)
      $il.Emit([OpCodes]::stloc_2)
      $il.Emit([OpCodes]::ldloc_1)
      $il.Emit([OpCodes]::bge_un_s, $labels[3])
      $il.Emit([OpCodes]::ldloc_3)
      $il.Emit([OpCodes]::neg)
      $il.Emit([OpCodes]::ldloc_s, $src)
      $il.Emit([OpCodes]::div)
      $il.Emit([OpCodes]::ret)

      Set-Variable -Name PSEntropy -Value (
        $e = $dm.CreateDelegate([Func[[Byte[]], Double]])
      ) -Option Constant -Scope Global -Visibility Private
    }
    '{0:F3}' -f $e.Invoke($Bytes)
  }
}
