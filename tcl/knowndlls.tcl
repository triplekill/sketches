if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM {HKEY_LOCAL_MACHINE}
set key  {SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs}

if {[catch {set vals [registry values "$HKLM\\$key"]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

foreach v $vals {
  if {[registry type "$HKLM\\$key" $v] eq "expand_sz"} {
    continue
  }

  puts [registry get "$HKLM\\$key" $v]
}
