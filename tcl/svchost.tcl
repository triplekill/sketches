if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Svchost}

if {[catch {set services [registry values $key]} e]} {
  puts stderr [concat "\[Error\]:" [lindex [split $e :] 0]]
  exit 1
}

foreach service $services {
   puts -nonewline "Service: $service\nPoints : "
   if {[catch {set points [regsub -all {\s+} [registry get $key $service] "\n\t "]}]} {
     puts ""
     continue
   }
   puts $points
   puts ""
}
