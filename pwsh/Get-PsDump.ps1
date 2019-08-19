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

function Get-PsDump {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateScript({!!($script:ps = Get-Process -Id $_ -ErrorAction 0)})]
    [Int32]$Id,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('MiniDump', 'FullDump')]
    [String]$DumpType = 'MiniDump',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [String]$SavePath = $pwd.Path
  )

  begin {
    $kernel32, $dmp = (New-Delegate kernel32 -Signature @{
      LoadLibraryW = [Func[[Byte[]], IntPtr]]
      FreeLibrary  = [Func[IntPtr, Boolean]]
    }), "${SavePath}\$($ps.Name)_${Id}.dmp"
  }
  process {}
  end {
    try {
      if (!($dll = $kernel32.LoadLibraryW.Invoke(
        [Encoding]::Unicode.GetBytes('dbghelp.dll')
      ))) { throw [DllNotFoundException]::new() }

      $dbghelp, $fs, $numeric = (New-Delegate dbghelp -Signature @{
        MiniDumpWriteDump =
          [Func[IntPtr, UInt32, SafeFileHandle, UInt32, IntPtr, IntPtr, IntPtr, Boolean]]
      }), [File]::Create($dmp), (0x006, 0x105)[$DumpType -eq 'MiniDump']

      if (!$dbghelp.MiniDumpWriteDump.Invoke(
        $ps.Handle, ${Id}, $fs.SafeFileHandle, $numeric,
        [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero
      )) {
        $err = $true
        throw [InvalidOperationException]::new()
      }
    }
    catch { Write-Verbose $_ }
    finally {
      if ($fs) { $fs.Dispose() }
      if ($dll) {
        if (!$kernel32.FreeLibrary.Invoke($dll)) {
          Write-Verbose 'Could not release dbghelp.dll library.'
        }
      }
      if ($err) { Remove-Item $dmp -Force -ErrorAction 0 }
    }

    $ps.Dispose()
  }
}
