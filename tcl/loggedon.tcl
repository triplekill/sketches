if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion}

proc err {val} {
  puts stderr [format "\[Error\]: %s" [lindex [split $val :] 0]]
}

proc uint_t {val} {
  return [format %u $val]
}

proc to_time {h l} {
  return [clock format [expr int(( \
    ([uint_t $h] << 32 | [uint_t $l]) - 116444736000000000 \
  ) / 10000000)] -format {%m-%d-%Y %H:%M:%S}]
}

if {[catch {set sid [registry get "$key\\Winlogon" AutoLogonSID]} e]} {
  err $e ; # very strange if this value does not appear
  exit 1
}

if {[catch {set values [registry values "$key\\ProfileList\\$sid"]} e]} {
  err $e ; # something wrong with SID
  exit 1
}

foreach i [lsearch -all -nocase -regexp $values {^local}] {
  set name [lindex $values $i]
  set $name [uint_t [registry get "$key\\ProfileList\\$sid" $name]]
}

puts "Logged off: [to_time $LocalProfileUnloadTimeHigh $LocalProfileUnloadTimeLow]"
puts "Logged  on: [to_time $LocalProfileLoadTimeHigh $LocalProfileLoadTimeLow]"
