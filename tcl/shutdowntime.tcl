if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key   {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Windows}
set epoch 116444736000000000 ; # epoch as FILETIME
set nano  10000000           ; # hundred nanoseconds

proc uint_t {val} {
  return [format %u $val]
}

if {[catch {binary scan [registry get $key ShutdownTime] ii l h} e]} {
  puts stderr [concat "\[Error\]:" [lindex [split $e :] 0]]
  exit 1
}

puts [clock format [expr ( \
  ([uint_t $h] << 32 | [uint_t $l]) - $epoch \
) / $nano] -format {%m-%d-%Y %H:%M:%S}]
