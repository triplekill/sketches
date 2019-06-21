if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\hivelist}

if {[catch {set lst [registry value $key]} e]} {
  puts stderr [concat "\[Error\]:" [lindex [split $e :] 0]]
  exit 1
}

foreach v $lst {
  puts "Hive: $v"
  puts "Path: [registry get $key $v]"
  puts ""
}
