if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating systsem.}
}

package require registry

set root {HKEY_LOCAL_MACHINE\SOFTWARE}
set auto {Microsoft\Windows NT\CurrentVersion\UAC\COMAutoApprovalList}
set item {Classes\CLSID}

proc err {val} {
  puts stderr [format "\[Error\]: %s" [lindex [split $val :] 0]]
  exit 1
}

proc printf {msg exp} {
  puts [format "\t%-23s: %s" $msg $exp]
}

if {[catch {set guids [registry value "$root\\$auto"]} e]} {err $e}
foreach guid $guids {
  if {[registry get "$root\\$auto" $guid] ne 1} { continue }
  # check COM existence
  if {[catch {set desc [registry get "$root\\$item\\$guid" {}]}]} {
    continue
  }
  if {[info exists desc]} {
    puts $desc
    printf GUID $guid
    set guid "$root\\$item\\$guid"
    foreach val [lrange [registry values $guid] 1 end] {
      printf $val [registry get $guid $val]
    }

    catch {set srv [registry get "$guid\\InProcServer32" {}]}
    if {[info exists srv]} { printf Path $srv }
    puts {}
  }
}
