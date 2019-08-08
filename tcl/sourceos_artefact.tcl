if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SYSTEM\Setup}
set arr {
  InstallDate
  InstallTime
  CurrentMajorVersionNumber
  CurrentMinorVersionNumber
  CurrentBuildNumber
  UBR
  BuildBranch
}

if {[catch {set keys [registry keys $key]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

proc uint_t {val} {
  return [format %u $val]
}

foreach k $keys {
  if {[regexp -nocase {^source.*\)$} $k]} {
    set sub "$key\\$k"
    set version {}
    puts $k
    foreach val [lrange $arr 2 5] {
      append version "." [registry get $sub $val]
    }
    puts [format "Version     : %s" [string trim $version "."]]
    puts [format "Build branch: %s" [registry get $sub [lindex $arr 6]]]
    puts [format "Install date: %s" [clock format \
      [registry get $sub [lindex $arr 0]] -format {%m-%d-%Y %H:%M:%S}]]
    binary scan [registry get $sub [lindex $arr 1]] ii l h
    puts [format "Install time: %s" [clock format \
      [expr int((([uint_t $h] << 32 | [uint_t $l]) - 116444736 * 1e9 \
      ) / 1e7)] -format {%m-%d-%Y %H:%M:%S}]]
    puts ""
  }
}
