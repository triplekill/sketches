if {"Windows NT" != $tcl_platform(os)} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set SOFTWARE {HKEY_LOCAL_MACHINE\SOFTWARE}
set key1 {Microsoft\Windows\CurrentVersion\Authentication\Credential Providers}
set key2 {Classes\CLSID}

if {[catch {set prov [registry keys "$SOFTWARE\\$key1"]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

foreach p $prov {
  if {[catch {set name [registry get "$SOFTWARE\\$key2\\$p" {}]}]} {
    continue ;# not existed, move to the next entry
  }
  puts [format "CLSID: %s\nName : %s\nPath : %s\n" \
    $p $name [registry get "$SOFTWARE\\$key2\\$p\\InProcServer32" {}]]
}
