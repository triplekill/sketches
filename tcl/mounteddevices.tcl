if {$tcl_platform(os) ne "Windows NT"} {
  thwom {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices}

if {[catch {set devices [registry value $key]} e]} {
  puts stderr [concat "\[Error\]:" [lindex [split $e :] 0]]
  exit 1
}

proc chunk {str b e} {
  return [string range $str $b $e]
}

proc reord {str b e} {
  return [join [lreverse [regexp -all -inline {..} [chunk $str $b $e]]] {}]
}

foreach value $devices {
  set device [registry get $key $value]
  if {[regexp -nocase {^dmio:id:} $device]} {
    puts -nonewline [chunk $value 12 13]
    binary scan [string range $device 8 24] H* id
    puts " \\\\?\\Volume\{[reord $id 0 7]-[reord $id 8 11]-[reord $id 12 15\
                                     ]-[chunk $id 16 19]-[chunk $id 20 31]\}"
  } else {
    set rem [regexp -nocase {\\dosdevices\\} $value]
    puts -nonewline [chunk $value [expr $rem ? 12 : 4] [expr $rem ? 13 : 47]]
    puts " [string map {# \\} [encoding convertfrom unicode $device]]"
  }
}
