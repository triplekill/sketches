#requires -version 6.1
using namespace System.IO
using namespace System.Text
using namespace System.Reflection
using namespace System.Reflection.Emit
using namespace Microsoft.Win32.SafeHandles
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
    ).Where{ $_.Name -cmatch '\AGet(Proc|Mod)' }.ForEach{
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
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateScript({$_ -ne [IntPtr]::Zero})]
    [IntPtr]$ProcAddress,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNull()]
    [Type]$Prototype,

    [Parameter(Position=2)]
    [ValidateNotNullOrEmpty()]
    [CallingConvention]$CallingConvention = 'StdCall'
  )

  process {
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
      $funcs.$_ = Set-Delegate -ProcAddress $addr.$_ -Prototype $Signature.$_
    }
    $funcs
  }
}

Set-Alias -Name pipelist -Value Get-PipeList
function Get-PipeList {
  [CmdletBinding()]param()

  process {
    $kernel32, $ntdll, $to_i = (New-Delegate kernel32 -Signature @{
      CreateFileW = [Func[
        [Byte[]], Int32, FileShare, IntPtr, FileMode, Int32, IntPtr, SafeFileHandle
      ]]
    }), (New-Delegate ntdll -Signature @{
      NtQueryDirectoryFile = [Func[
        SafeFileHandle, IntPtr, IntPtr, IntPtr, [Byte[]], IntPtr, UInt32, UInt32,
        Boolean, IntPtr, Boolean, Int32
      ]]
    }), "ToInt$((32, 64)[($sz = [IntPtr]::Size) / 4 - 1])"

    if (!($pipes = $kernel32.CreateFileW.Invoke(
      [Encoding]::Unicode.GetBytes('\\.\pipe\'), 0x80000000, [FileShare]::Read,
      [IntPtr]::Zero, [FileMode]::Open, 0, [IntPtr]::Zero
    ))) { throw [InvalidOperationException]::new() }

    $query, $isb = $true, [Byte[]]::new($sz) # IO_STATUS_BLOCK
    try {
      $dir = [Marshal]::AllocHGlobal(4096) # one page should be enough

      while (1) {
        if ($ntdll.NtQueryDirectoryFile.Invoke(
          $pipes, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero,
          $isb, $dir, 4096, 1, $false, [IntPtr]::Zero, $query
        ) -ne 0) { break }

        $tmp = $dir
        while (1) {
          $NextEntryOffset = [Marshal]::ReadInt32($tmp)
          $EndOfFile = [Marshal]::ReadInt64($tmp, 0x28)
          $AllocationSize = [Marshal]::ReadInt64($tmp, 0x30)
          $FileNameLength = [Marshal]::ReadInt32($tmp, 0x3C) / 2
          [PSCustomObject]@{
            PipeName = [Marshal]::PtrToStringUni(
              [IntPtr]($tmp.$to_i() + 0x40), $FileNameLength
            )
            Instances = $EndOfFile
            MaxInstances = [BitConverter]::ToInt32(
              [BitConverter]::GetBytes($AllocationSize)[0..3], 0
            )
          }

          if (!$NextEntryOffset) { break }
          $tmp = [IntPtr]($tmp.$to_i() + $NextEntryOffset)
        }

        $query = $false
      }
    }
    catch { Write-Verbose $_ }
    finally {
      if ($dir) { [Marshal]::FreeHGlobal($dir) }
    }

    $pipes.Dispose()
  }
}
