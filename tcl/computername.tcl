if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM {HKEY_LOCAL_MACHINE}
set key  {SYSTEM\CurrentControlSet\Control\ComputerName}

if {[catch {set keys [registry keys "$HKLM\\$key"]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

foreach k $keys {
  puts [format "%-18s: %s" $k [ \
                 registry get "$HKLM\\$key\\$k" ComputerName]]
}
