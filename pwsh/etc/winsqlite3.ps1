using namespace System.Text
using namespace System.Reflection
using namespace System.Linq.Expressions
using namespace System.Runtime.InteropServices

$keys, $types = ($x = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys, @{
  buf = [Byte[]]
  ptr = [IntPtr]
  ptr_ = [IntPtr].MakeByRefType()
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
      $_.Name -cmatch '\AGet(P|M)'
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

      if (($fnsig = $kernel32.GetProcAddress.Invoke($null, @($mod, $fname))
      ) -eq [IntPtr]::Zero) {
        throw [InvalidOperationException]::new("Cannot find $fname signature.")
      }

      $fnargs = $def.Pipeline.Extent.Text
      [Object[]]$fnargs = [String]::IsNullOrEmpty($fnargs) ? $fnret : (
        ($fnargs -replace '\[|\]' -split ',\s+?') + $fnret
      )

      $funcs[$fname] = $fn.MakeGenericMethod(
        [Delegate]::CreateDelegate([Func[[Type[]], Type]], $m).Invoke($fnargs)
      ).Invoke([Marshal], $fnsig)
    }
    Set-Variable -Name $Module -Value $funcs -Scope Script -Force
  }
}

function New-SqliteDB {
  <#
    .SYNOPSIS
        Concept of usage winsqlite3.dll library for creating database.
    .EXAMPLE
        New-SqliteDB -Sql @'
        create table if not exists tbl(
           id int primary key not null,
           name text not null,
           age int not null
        );
        insert into tbl values(1, "Anna", 27);
        insert into tbl values(2, "Will", 53);
        insert into tbl values(3, "Jack", 13);
        '@
    .LINK
        https://www.sqlite.org
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$Sql,

    [Parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [String]$DataBase = "$($pwd.Path)\test.db"
  )

  begin {
    New-Delegate kernel32 {
      ptr LoadLibraryW([buf])
      bool FreeLibrary([ptr])
    }

    if (($libsqlite = $kernel32.LoadLibraryW.Invoke(
      [Encoding]::Unicode.GetBytes('winsqlite3.dll')
    )) -eq [IntPtr]::Zero) {
      throw [InvalidOperationException]::new('Cannot find winsqlite3.dll library.')
    }

    New-Delegate winsqlite3 {
      int sqlite3_close([ptr])
      ptr sqlite3_errmsg([ptr])
      int sqlite3_exec([ptr, buf, ptr, ptr, ptr_])
      int sqlite3_free([ptr])
      int sqlite3_open([buf, ptr_])
    }

    $SQLITE_OK = 0 # operation success
  }
  process {}
  end {
    try {
      $db = [IntPtr]::Zero
      if ($winsqlite3.sqlite3_open.Invoke(
        [Encoding]::UTF8.GetBytes($DataBase), [ref]$db
      ) -ne $SQLITE_OK) {
        throw [InvalidOperationException]::new(
          [Marshal]::PtrToStringAnsi($winsqlite3.sqlite3_errmsg.Invoke($db))
        )
      }

      $err = [IntPtr]::Zero
      if ($winsqlite3.sqlite3_exec.Invoke(
        $db, [Encoding]::Ascii.GetBytes($Sql), [IntPtr]::Zero, [IntPtr]::Zero, [ref]$err
      ) -ne $SQLITE_OK) {
        $msg = [Marshal]::PtrToStringAnsi($err)
        $winsqlite3.sqlite3_free.Invoke($err)
        throw [InvalidOperationException]::new($msg)
      }
    }
    catch {Write-Verbose $_}
    finally {
      if ($db -and $db -ne [IntPtr]::Zero) {
        if ($winsqlite3.sqlite3_close.Invoke($db) -ne $SQLITE_OK) {
          Write-Verbose 'sqlite3_close fatal error.'
        }
      }
    }

    if ($libsqlite -and $libsqlite -ne [IntPtr]::Zero) {
      if (!$kernel32.FreeLibrary.Invoke($libsqlite)) {
        Write-Verbose 'FreeLibrary fatal error.'
      }
    }
  }
}
