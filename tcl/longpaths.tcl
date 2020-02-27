if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem}

if {[catch {set lpe [registry get $key LongPathsEnabled]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

set status [list disabled enabled]
puts "LongPaths feature is [lindex $status $lpe]."
