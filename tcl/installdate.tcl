if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion}
set epoch 116444736000000000 ; # epoch as FILETIME
set nano  10000000           ; # hundred nanoseconds

proc uint_t {val} {
  return [format %u $val]
}

proc err {val} {
  puts stderr "Perhaps \"$val\" value does not exist."
  exit 1
}

if {[catch {set sec [registry get $key InstallDate]}]} {
  err InstallDate ; # REG_DWORD
}

puts [clock format $sec -format {%m-%d-%Y %H:%M:%S}]

# another approach
if {[catch {binary scan [registry get $key InstallTime] ii l h}]} {
  err InstallTime ; # REG_QWORD
}

puts [clock format [expr int(( \
  ([uint_t $h] << 32 | [uint_t $l]) - $epoch \
) / $nano)] -format {%m-%d-%Y %H:%M:%S}]
