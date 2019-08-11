#requires -version 6.1
using namespace System.Reflection
using namespace System.Reflection.Emit
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

    $il.Emit([OpCodes]::"ldc_i$sz", $ProcAddress."ToInt$((32, 64)[$sz/ 4 - 1])"())
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

function Get-Clipboard {
  <#
    .SYNOPSIS
        Get textual data from the clipboard.
    .DESCRIPTION
        The main goal of `Get-Clipboard` to locate and show the textual data of
        the clipboard, no more. It's very useful when you often use the clipboard.
    .PARAMETER AsArray
        Indicates behaviour of the clipboard data representation. If you set this
        parameter as `RemoveEmptyEntries` then there will be returned an array of
        strings excluding empty lines. Set this `Simple` to keep empty lines.
    .INPUTS
        None
    .OUTPUTS
        System.String, System.String[]
    .EXAMPLE
        Get-ChildItem | clip
        Get-Clipboard

        Data extracted from the clipboard will be represented like a single string.
    .EXAMPLE
        Get-Clipboard -AsArray RemoveEmptyEntries

        Data extracted from the clipboard will be represented like an array of
        strings. All empty lines will be removed.
    .NOTES
        MIT
    .LINK
        None
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateSet('Simple', 'RemoveEmptyEntries')]
    [String]$AsArray
  )

  begin {
    $kernel32 = New-Delegate kernel32 @{
      GlobalLock = [Func[IntPtr, IntPtr]]
      GlobalUnlock = [Func[IntPtr, Boolean]]
    }

    $user32 = New-Delegate user32 @{
      CloseClipboard = [Func[Boolean]]
      EnumClipboardFormats = [Func[UInt32, UInt32]]
      GetClipboardData = [Func[UInt32, IntPtr]]
      OpenClipboard = [Func[IntPtr, Boolean]]
    }

    function private:Test-ClipFormat([UInt32]$Format) {
      process {
        $query = $true

        for ($i = 0;
             $query -bor $i -ne 0;
             $i = $user32.EnumClipboardFormats.Invoke($i)) {
          $query = $false
          if ($i -eq $Format) { return $true }
        }

        return $false
      }
    }
  }
  process {}
  end {
    if ($user32.OpenClipboard.Invoke([IntPtr]::Zero)) {
      Write-Verbose 'clipboard has been successfully opened'

      try {
        if (!(Test-ClipFormat 13)) { # CF_UNICODETEXT
          throw 'clipboard does not contain any textual data'
        }

        if (($data = $user32.GetClipboardData.Invoke(13)) -eq [IntPtr]::Zero) {
          throw 'clipboard retrieval failed'
        }

        if (($ptxt = $kernel32.GlobalLock.Invoke($data)) -eq [IntPtr]::Zero) {
          throw 'locking memory failed'
        }

        $text = [Marshal]::PtrToStringAuto($ptxt)
        switch ($AsArray) {
          'Simple' { $text -split "`n" }
          'RemoveEmptyEntries' { ($text -split "`n").Where{$_ -match '\S'} }
          default { $text }
        }
      }
      catch {
        Write-Verbose $_
      }
      finally {
        if ($text) {
          if (!$kernel32.GlobalUnlock.Invoke($data)) {
            Write-Verbose 'unlocking memory failed'
          }
        }
      }

      if ($user32.CloseClipboard.Invoke()) {
        Write-Verbose 'clipboard has been successfully closed'
      }
    }
  }
}
