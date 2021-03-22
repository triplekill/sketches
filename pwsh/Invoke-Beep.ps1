using namespace System.Text
using namespace System.Reflection
using namespace System.ComponentModel
using namespace System.Reflection.Emit
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices
#################################################################################################
#############     Accessing Beep driver without third party tools and assemblies     ############
#############                        Add-Type cmdlet free                            ############
#############                                                                        ############
#################################################################################################
if (![Environment]::Is64BitOperatingSystem) {
  throw [InvalidOperationException]::new('PoC requires x64 system.')
}

$requires = @{GetProcAddress = [IntPtr]::Zero; GetModuleHandleW = [IntPtr]::Zero}
$ib = ($ps = Get-Process -Id $pid).Modules.Where{$_.ModuleName -match 'kernel32'}.BaseAddress
$ps.Dispose()

$va = [Marshal]::ReadInt32([IntPtr]([Marshal]::ReadInt32($ib, 0x3C) + $ib.ToInt64() + 0x88))
$nn = [Marshal]::ReadInt32($ib, $va + 0x18) # number of names
$af = [Marshal]::ReadInt32($ib, $va + 0x1C) # address of functions
$an = [Marshal]::ReadInt32($ib, $va + 0x20) # address of names

$tmp = $ib.ToInt64()
(0..($nn - 1)).ForEach{
  if (($name = [Marshal]::PtrToStringAnsi(
    [IntPtr]($tmp + [Marshal]::ReadInt32([IntPtr]($tmp + $an + $_ * 4)))
  )) -in $requires.Keys) {
    $requires[$name] = $tmp + [Marshal]::ReadInt32([IntPtr]($tmp + $af + $_ * 4))
  }
}

$delegate = {
  param([IntPtr]$a, [Type]$p, [CallingConvention]$cc = 'StdCall')

  end {
    $method = $p.GetMethod('Invoke')
    $returntype, $parameters = $method.ReturnType, $method.GetParameters().ParameterType
    $il = ($holder = [DynamicMethod]::new('Invoke', $returntype, $parameters, $p)).GetILGenerator()

    if ($parameters) {
      (0..($parameters.Length - 1)).ForEach{ $il.Emit([OpCodes]::ldarg, $_) }
    }
    $il.Emit([OpCodes]::ldc_i8, $a.ToInt64())
    $il.EmitCalli([OpCodes]::calli, $cc, $returntype, $parameters)
    $il.Emit([OpCodes]::ret)

    $holder.CreateDelegate($p)
  }
}

$delegates = {
  param([String]$d, [ScriptBlock]$s)

  end {
    $GetProcAddress = & $delegate $requires.GetProcAddress ([Func[IntPtr, String, IntPtr]])
    $GetModuleHandle = & $delegate $requires.GetModuleHandleW ([Func[[Byte[]], IntPtr]])

    if (($mod = $GetModuleHandle.Invoke([Encoding]::Unicode.GetBytes($d))) -eq [IntPtr]::Zero) {
      throw [DllNotFoundException]::new("Cannot find $d library.")
    }

    $funcs = @{}
    for ($i, $m, $fn, $p = 0, ([Expression].Assembly.GetType(
        'System.Linq.Expressions.Compiler.DelegateHelpers'
       ).GetMethod('MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static')
       ), [Marshal].GetMethod('GetDelegateForFunctionPointer', ([IntPtr])),
       $s.Ast.FindAll({$args[0].CommandElements}, $true).ToArray();
       $i -lt $p.Length; $i++
    ) {
      $fnret, $fname = ($def = $p[$i].CommandElements).Value

      if (($fnsig = $GetProcAddress.Invoke($mod, $fname)) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = [String]::IsNullOrEmpty($fnargs) ? $fnret : (
        ($fnargs -replace '\[|\]' -split ',\s+').ForEach{
          $_.StartsWith('_') ? (Get-Variable $_.Remove(0, 1) -ValueOnly) : $_
        } + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }

    Set-Variable -Name $d -Value $funcs -Scope Script -Force
  }
}

$buf, $ptr, $ptr_ = [Byte[]], [IntPtr], [IntPtr].MakeByRefType()

& $delegates kernel32 {
  bool CloseHandle([_ptr])
  bool DeviceIoControl([_ptr, uint, _buf, uint, _ptr, uint, _buf, _ptr])
}

& $delegates ntdll {
  void RtlInitUnicodeString([_buf, _buf])
  int  RtlNtStatusToDosError([int])
  int  NtCreateFile([_ptr_, int, _buf, _buf, _ptr, uint, uint, uint, uint, _ptr, uint])
}

$uni = [Byte[]]::new(($psz = [IntPtr]::Size) * 2) # UNICODE_STRING
$ntdll.RtlInitUnicodeString.Invoke($uni, [Encoding]::Unicode.GetBytes('\Device\Beep'))

$isb = [Byte[]]::new($psz * 2) # IO_STATUS_BLOCK (take but not check)
try {
  $gch = [GCHandle]::Alloc($uni, [GCHandleType]::Pinned)
  [Byte[]]$obj = [BitConverter]::GetBytes($psz * 6) + (
    ,0 * (4 + $psz) # OBJECT_ATTRIBUTES initialization
  ) + [BitConverter]::GetBytes(
    $gch.AddrOfPinnedObject().ToInt64()
  ) + (,0 * ($psz * 3))

  $hndl = [IntPtr]::Zero
  if (0 -ne ($nts = $ntdll.NtCreateFile.Invoke(
    [ref]$hndl, 0x80000000, $obj, $isb, [IntPtr]::Zero, 128, 1, 3, 0, [IntPtr]::Zero, 0
  ))) { throw [Win32Exception]::new($ntdll.RtlNtStatusToDosError.Invoke($nts)) }

  [Byte[]]$beep = [BitConverter]::GetBytes(1000) + [BitConverter]::GetBytes(700)
  $ret = [Byte[]]::new(4)
  [void]$kernel32.DeviceIoControl.Invoke(
    $hndl, (1 -shl 16), $beep, $beep.Length, [IntPtr]::Zero, 0, $ret, [IntPtr]::Zero
  )
}
catch { Write-Host $_ }
finally {
  if ($hndl -and $hndl -ne [IntPtr]::Zero) {
    if (!$kernel32.CloseHandle.Invoke($hndl)) { Write-Warning 'device has not been released.' }
  }

  if ($gch) { $gch.Free() }
}
