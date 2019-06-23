if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion}
set epoch 116444736000000000 ; # epoch as FILETIME
set nano  10000000           ; # hundred nanoseconds

proc uint_t {val} {
  return [expr $val < 0 ? $val & 0xFFFFFFFF : $val]
}

if {[catch {set sec [registry get $key InstallDate]}]} {
  puts stderr "Perhaps \"InstallDate\" value does not exist."
  exit 1
}

puts [clock format $sec -format {%m-%d-%Y %H:%M:%S}]

# another approach (InstallDate -> REG_QWORD)
if {[catch {binary scan [registry get $key InstallTime] ii l h}]} {
  puts stderr "Perhaps \"InstallTime\" value does not exist."
  exit 1
}

puts [clock format [expr ( \
  ([uint_t $h] << 32 | [uint_t $l]) - $epoch \
) / $nano] -format {%m-%d-%Y %H:%M:%S}]
