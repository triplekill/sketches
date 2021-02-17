if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set root {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services}

if {[catch {set subs [registry keys $root]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

foreach s $subs {
  if {[catch {set type [registry get "$root\\$s" Type]}]} {
    continue
  }

  if {$type >= 3} { continue }

  if {[catch {set path [registry get "$root\\$s" ImagePath]}]} {
    continue
  }

  set arr [split $path "\\"]
  puts [lindex $arr [expr {[llength $arr] - 1}]]
}
