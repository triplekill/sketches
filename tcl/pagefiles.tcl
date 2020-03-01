if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM {HKEY_LOCAL_MACHINE}
set key  {SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management}

if {[catch {set pagefiles [registry get "$HKLM\\$key" ExistingPageFiles]} e]} {
  puts stderr [concat "\[Error\]:" [lindex [split $e :] 0]]
  exit 1
}

foreach pf $pagefiles {
  puts $pf
}
