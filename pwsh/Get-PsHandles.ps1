#requires -version 6.1
using namespace System.Reflection
using namespace System.Reflection.Emit
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices

function Get-ProcAddress {
  [OutputType([Hashtable])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Module,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Function
  )

  process {
    $kernel32 = @{}

    [Assembly]::LoadFile("$(
      [RuntimeEnvironment]::GetRuntimeDirectory()
    )Microsoft.Win32.SystemEvents.dll"
    ).GetType('Interop+Kernel32').GetMethods(
      [BindingFlags]'NonPublic, Static, Public'
    ).Where{$_.Name -cmatch '\AGet(Proc|Mod)'}.ForEach{
      $kernel32[$_.Name] = $_
    }

    if ((
      $mod = $kernel32.GetModuleHandle.Invoke($null, @($Module))
    ) -eq [IntPtr]::Zero) {
      throw [DllNotFoundException]::new()
    }

    $funcs = @{}
    $Function.ForEach{
      if ((
        $$ = $kernel32.GetProcAddress.Invoke($null, @($mod, $_))
      ) -ne [IntPtr]::Zero) { $funcs.$_ = $$ }
    }
    $funcs
  }
}

function Set-Delegate {
  [OutputType([Type])]
  [CmdletBinding(DefaultParameterSetName='Prototype')]
  param(
    [Parameter(Mandatory, ParameterSetName='Prototype', Position=0)]
    [ValidateNotNull()]
    [Alias('p')]
    [Type]$Prototype,

    [Parameter(Mandatory, ParameterSetName='PrototypeAsTypesArray', Position=0)]
    [ValidateNotNullOrEmpty()]
    [Alias('pa')]
    [Type[]]$PrototypeAsTypesArray,

    [Parameter(Mandatory, Position=1)]
    [ValidateScript({$_ -ne [IntPtr]::Zero})]
    [IntPtr]$ProcAddress,

    [Parameter(Position=2)]
    [ValidateNotNullOrEmpty()]
    [CallingConvention]$CallingConvention = 'StdCall'
  )

  process {
    switch ($PSCmdlet.ParameterSetName) {
      'Prototype' {
        $method = $Prototype.GetMethod('Invoke')
        $returntype, $paramtypes = $method.ReturnType, $method.GetParameters().ParameterType
        $paramtypes = ($paramtypes, $null)[!$paramtypes]
        $il, $sz = ($holder = [DynamicMethod]::new(
          'Invoke', $returntype, $paramtypes, $Prototype
        )).GetILGenerator(), [IntPtr]::Size

        if ($paramtypes) {
          (0..($paramtypes.Length - 1)).ForEach{$il.Emit([OpCodes]::ldarg, $_)}
        }

        $il.Emit([OpCodes]::"ldc_i$sz", $ProcAddress."ToInt$((32, 64)[$sz / 4 - 1])"())
        $il.EmitCalli([OpCodes]::calli, $CallingConvention, $returntype, $paramtypes)
        $il.Emit([OpCodes]::ret)

        $holder.CreateDelegate($Prototype)
      }
      'PrototypeAsTypesArray' {
        [Marshal]::GetDelegateForFunctionPointer(
          $ProcAddress, [Delegate]::CreateDelegate(
            [Func[[Type[]], Type]],
            [Expression].Assembly.GetType(
              'System.Linq.Expressions.Compiler.DelegateHelpers'
            ).GetMethod(
              'MakeNewCustomDelegate', [BindingFlags]'NonPublic, Static'
            )
          ).Invoke($PrototypeAsTypesArray)
        )
      }
    } # switch
  }
}

function New-Delegate {
  [OutputType([Hashtable])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Module,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNull()]
    [Hashtable]$Signature
  )

  process {
    $funcs, $addr = @{}, (Get-ProcAddress -Module $Module -Function $Signature.Keys)
    $addr.Keys.ForEach{
      $ptr, $sig = $addr.$_, $Signature.$_
      if (!$sig) { throw [InvalidOperationException]::new() }
      $funcs.$_ = switch -Regex ($sig.Name) {
        '\A(Action|Func)' { Set-Delegate -ProcAddress $ptr -Prototype $sig }
        default { Set-Delegate -ProcAddress $ptr -PrototypeAsTypesArray $sig }
      }
    }
    $funcs
  }
}

function Get-PsHandles {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateScript({!!($script:ps = Get-Process -Id $_ -ErrorAction 0) -and $_ -ne $PID})]
    [Int32]$Id,

    [Parameter()][Switch]$ShowEmpty
  )

  begin {
    $kernel32, $ntdll, $page, $to_i = (New-Delegate kernel32 -Signature @{
      CloseHandle = [Func[IntPtr, Boolean]]
      OpenProcess = [Func[UInt32, Boolean, Int32, IntPtr]]
    }), (New-Delegate ntdll -Signature @{
      NtDuplicateObject = (
        [IntPtr], [IntPtr], [IntPtr], [IntPtr].MakeByRefType(),
        [UInt32], [UInt32], [UInt32], [Int32]
      )
      NtQueryInformationProcess = [Func[IntPtr, Int32, IntPtr, Int32, [Byte[]], Int32]]
      NtQueryObject = [Func[IntPtr, UInt32, [Byte[]], UInt32, [Byte[]], Int32]]
    }), [Byte[]]::new(0x1000), "ToInt$((32, 64)[($x = ($sz = [IntPtr]::Size) / 4 - 1)])"

    function Expand-UnicodeString([IntPtr]$h, [UInt32]$o) {
      if (!$ntdll.NtQueryObject.Invoke($h, $o, $page, $page.Length, $null)) {
        try {
          $uni = [GCHandle]::Alloc($page, [GCHandleType]::Pinned)
          $str = $uni.AddrOfPinnedObject()
          [Marshal]::PtrToStringUni([Marshal]::ReadIntPtr([IntPtr]($str.$to_i() + $sz)))
        }
        catch { Write-Verbose $_ }
        finally {
          if ($uni) { $uni.Free() }
        }
      }
    }
  }
  process {
    try {
      if (($hndl = $kernel32.OpenProcess.Invoke(0x440, $false, $Id)) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new()
      }

      $ptr = [Marshal]::AllocHGlobal(($bufsz = 0x1000))
      while ($ntdll.NtQueryInformationProcess.Invoke($hndl, 51, $ptr, $bufsz, $null)) {
        $ptr = [Marshal]::ReAllocHGlobal($ptr, [IntPtr]($bufsz *= 2))
      }

      $tmp = $ptr
      $NumberOfHandles = [Marshal]::ReadIntPtr($tmp).$to_i()
      $handles = (0..($NumberOfHandles - 1)).ForEach{
        $HandleValue = [Marshal]::ReadIntPtr([IntPtr]($tmp.$to_i() + (0x08, 0x10)[$x]))
        [IntPtr]$duple = [IntPtr]::Zero
        if (!$ntdll.NtDuplicateObject.Invoke(
          $hndl, $HandleValue, [IntPtr]-1, [ref]$duple, 0, 0, 0x02
        )) {
          $tmp = [IntPtr]($tmp.$to_i() + (0x1C, 0x28)[$x])
          continue
        }
        $page.Clear()
        $type = Expand-UnicodeString $duple 2
        $page.Clear()
        $name = Expand-UnicodeString $duple 1

        if ($duple -ne [IntPtr]::Zero) {
          if (!$kernel32.CloseHandle.Invoke($duple)) {
            Write-Verbose "Could not close duple $($HandleValue.$to_i()) handle."
          }
        }

        [PSCustomObject]@{
          Value = '0x{0:X}' -f $HandleValue.$to_i()
          Type  = $type
          Name  = $name
        }

        $tmp = [IntPtr]($tmp.$to_i() + (0x1C, 0x28)[$x])
      }
    }
    catch { Write-Verbose $_ }
    finally {
      if ($ptr) {[Marshal]::FreeHGlobal($ptr)}
      if ($hndl -and $hndl -ne [IntPtr]::Zero) {
        if (!$kernel32.CloseHandle.Invoke($hndl)) {
          Write-Verbose "Could not close process handle."
        }
      }
    }
  }
  end {
    $ps.Dispose()
    if ($handles) {($handles, $handles.Where{$_.Name})[!$ShowEmpty]}
    [GC]::Collect()
  }
}
