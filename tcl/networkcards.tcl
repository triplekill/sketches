if {$tcl_platform(os) != "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKLM  {HKEY_LOCAL_MACHINE}
set cards {SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards}
set inter {SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces}

proc err {val} {
  puts stderr [format "\[Error\]: %s" [lindex [split $val :] 0]]
}

if {[catch {set nums [registry keys "$HKLM\\$cards"]} e]} {
  err $e ; # failed to get description of network cards
  exit 1
}

foreach num $nums {
  set card "$HKLM\\$cards\\$num"
  if {[catch {set id [registry get $card ServiceName]} e]} {
    err $e ; # failed to get network interface id
    continue
  }
  # that's OK, show network card name
  puts [format "%s\n%s" [registry get $card Description] [string repeat - 47]]
  # read data of specified network interface
  set id "$HKLM\\$inter\\$id"
  if {[catch {set vals [registry values $id]}]} {
    puts {}
    continue
  }

  foreach val $vals {
    if {[registry type $id $val] != "binary"} {
      if {[regexp -nocase {^(t\d|l.*time)$} $val]} {
        puts [format "%-27s: %s" $val [clock format \
         [registry get $id $val] -format {%m-%d-%Y %H:%M:%S}]]
      } else {
        puts [format "%-27s: %s" $val [registry get $id $val]]
      }
    }
  }

  puts {}
}
