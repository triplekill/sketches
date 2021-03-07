if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\DeviceDirectory}

proc uint_t {val} {
  return [format %u $val]
}

if {[catch {binary scan [registry get $key LastFullRefreshTimestamp] ii l h} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

puts [clock format [expr int([expr ( \
  ([uint_t $h] << 32 | [uint_t $l]) - 116444736 * 1e9) / 1e7 \
])] -format {%m-%d-%Y %H:%M:%S}]
