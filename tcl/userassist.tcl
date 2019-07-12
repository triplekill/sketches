if {"Windows NT" != $tcl_platform(os) || "5.1" != $tcl_platform(osVersion)} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKCU {HKEY_CURRENT_USER}
set key  {Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist}

proc rot13 {str} {
  set res {}
  foreach c [split $str {}] {
    set n [scan $c %c]
    set n [expr $n >= 65 && $n <= 90 || $n >= 97 && $n <= 122 ? \
                 [expr $n + [expr $n % 32 < 14 ? 13 : -13]] : $n]
    set res ${res}[format %c $n]
  }

  return $res
}

if {[catch {set keys [registry keys "$HKCU\\$key"]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

foreach k $keys {
  if {[catch {set vals [registry values "$HKCU\\$key\\$k\\Count"]}]} {
    continue ; # just move to the next item
  }

  foreach val $vals { puts [rot13 $val] }
}
