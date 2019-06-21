if {$tcl_platform(os) ne  "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key   {HKEY_LOCAL_MACHINE\SYSTEM\DriverDatabase}
set epoch 116444736000000000 ; # epoch as FILETIME
set nano  10000000           ; # hundred nanoseconds

if {[catch {binary scan [registry get $key updatedate] ii l h} e]} {
  puts stderr [concat "\[Error\]: " [lindex [split $e :] 0]]
  exit 1
}

puts [clock format [expr ( \
  ($h << 32 | $l) - $epoch \
) / $nano] -format {%m-%d-%Y %H:%M:%S}]
