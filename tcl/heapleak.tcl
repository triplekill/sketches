if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM {HKEY_LOCAL_MACHINE}
set key  {SOFTWARE\Microsoft\RADAR\HeapLeakDetection\DiagnosedApplications}

proc uint_t {val} {
  return [expr $val < 0 ? $val & 0xFFFFFFFF : $val]
}

if {[catch {set apps [registry keys "$HKLM\\$key"]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

puts [format "%-47s %s" Application LastLeakStamp]
puts [format "%-47s %s" ----------- -------------]
foreach app $apps {
  binary scan [registry get "$HKLM\\$key\\$app" LastDetectionTime] ii l h
  set sec [expr int((([uint_t $h] << 32 | [uint_t $l]) - 116444736 * 1e9) / 1e7)]
  puts [format "%-47s %s" $app [clock format $sec -format {%m-%d-%Y %H:%M:%S}]]
}
