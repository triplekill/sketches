if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operaing system.}
}

package require registry

set mui {MuiCache}
set key {HKEY_CURRENT_USER}
set key [format "%s\\%s" $key {Software\Classes\Local Settings}]
set lst [list "Immutable$mui\\Strings" "Software\\Microsoft\\Windows\\Shell\\$mui"]

proc err {val} {
  puts stderr [format "\[Error\]: %s" [lindex [split $val :] 0]]
  exit 1
}

proc mui {val} {
  foreach v [registry values $val] {
    set fmt [registry type $val $v]
    if {$fmt != "multi_sz" && $fmt != "binary"} {
      puts [format "Path : %s\nDesc : %s\n" $v [registry get $val $v]]
    }
  }
}

set cur "$key\\[lindex $lst 0]" ; # ImmutableMuiCache
if {[catch {set str [registry key $cur]} e]} { err $e }
if {[info exists str]} { ; # system entries
  set cur "$cur\\$str"
  puts "Immutable entries\n[string repeat = 73]"
  mui $cur

  set cur "$key\\$mui"
  set cur "$cur\\[registry key $cur]\\$str" ; # MuiCache
  puts "System entries\n[string repeat = 73]"
  mui $cur
}

set cur "$key\\[lindex $lst 1]"
puts "User entries\n[string repeat = 73]"
mui $cur
