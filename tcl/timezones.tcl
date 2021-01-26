if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones}

proc err {val} {
  puts stderr [format "\[Error\]: %s" [lindex [split $val :] 0]]
}

if {[catch {set zones [registry keys $key]} e]} {
  err $e
  exit 1
}

foreach zone $zones {
  if {[catch {set offset [registry get "$key\\$zone" Display]}]} {continue}
  puts [format "Key: %s\nOfs: %s\n" $zone $offset]
}
