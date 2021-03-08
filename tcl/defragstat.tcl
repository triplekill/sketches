if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM {HKEY_LOCAL_MACHINE}
set stat "$HKLM\\SOFTWARE\\Microsoft\\Dfrg\\Statistics"
set devs "$HKLM\\SYSTEM\\MountedDevices"

proc err {val} {
  puts stderr [format "\[Error\]: %s" [lindex [split $val :] 0]]
  exit 1
}

proc reord {str b e} {
  return [join [lreverse [regexp -all -inline {..} [string range $str $b $e]]] {}]
}

proc toguid {str} {
  return "Volume\{[reord $str 0 7]-[reord $str 8 11]-[reord $str 12 15\
                          ]-[string range $str 16 19]-[string range $str 20 31]\}"
}

if {[catch {set devices [registry value $devs]} e]} {err $e}
set points [dict create] ;# mounted points
foreach value $devices {
  set device [registry get $devs $value]
  if {[regexp -nocase {^dmio:id:} $device]} {
    binary scan [string range $device 8 24] H* raw
    dict set points [toguid $raw] [string range $value 12 13]
  }
}

if {[catch {set volumes [registry keys $stat]} e]} {err $e}
foreach volume $volumes {
  if {[catch {set letter [dict get $points $volume]} ]} {
    puts [format "Disk: *** no letter ***\n\tPoint: \\\\?\\%s" $volume]
  } else {
    puts [format "Disk: %.1s\n\tPoint: \\\\?\\%s" $letter $volume]
  }
  puts [format "\tCluster size: %d Kb" [expr [registry get "$stat\\$volume" BytesPerCluster] / 1024]]
  puts [format "\tFragmented files: %d" [registry get "$stat\\$volume" FragmentedFiles]]
  puts [format "\tDirectories count: %d" [registry get "$stat\\$volume" DirectoryCount]]
  puts [format "\tFragmented directories: %d" [registry get "$stat\\$volume" FragmentedDirectories]]
  puts [format "\tMovable files and directories: %d" [registry get "$stat\\$volume" MovableFiles]]
  puts [format "\tUnmovable files and directories: %d" [registry get "$stat\\$volume" UnmovableFiles]]
  puts {}
}
