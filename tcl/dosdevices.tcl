if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM {HKEY_LOCAL_MACHINE}
set key  {SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices}

if {[catch {set vals [registry values "$HKLM\\$key"]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

puts [format "%-9s %s" Name Path]
puts [format "%-9s %s" ---- ----]
foreach val $vals {
  puts [format "%-9s %s" $val [registry get "$HKLM\\$key" $val]]
}
