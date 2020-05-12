if {"Windows NT" != $tcl_platform(os)} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SecurityManager\CapabilityClasses}

if {[catch {set sids [registry get $key AllCachedCapabilities]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

foreach sid [lsort $sids] {
  puts $sid
}
