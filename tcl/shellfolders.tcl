if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

proc reg_path {val} {
  set key {HKEY_CURRENT_USER}
  set key [format "%s\\%s" $key {Software\Microsoft\Windows\CurrentVersion\Explorer}]

  if {[catch {set tmp [registry values "$key\\$val"]} e]} {
    puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  }

  if {[info exists tmp]} {
    foreach v [lsort $tmp] {
      if {![string match "!*" $v]} {
        puts [format "Name(ID) : %s\nPath     : %s\n" $v [registry get "$key\\$val" $v]]
      }
    }
  }
}

puts "Common folders\n[string repeat = 73]"
reg_path {Shell Folders}
puts "Personal folders\n[string repeat = 73]"
reg_path {User Shell Folders}
