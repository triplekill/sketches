if {$tcl_platform(os) ne "Windows NT"} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set HKCU {HKEY_CURRENT_USER}
set key  {Software\Classes\Local Settings\Software\Microsoft}
set key [format "%s\\%s\\%s" $HKCU $key {Windows\CurrentVersion\TrayNotify}]

if {[catch {set vals [registry values $key]} e]} {
  puts stderr [format "\[Error\]: %s" [list [split $e :] 0]]
  exit 1
}

proc rot13 {val} {
  set str ""
  foreach c [split $val {}] {
    set n [scan $c %c]
    set n [expr $n >= 65 && $n <= 90 || $n >= 97 && $n <= 122 ? \
                 [expr $n + [expr $n % 32 < 14 ? 13 : -13]] : $n]
    set str ${str}[format %c $n]
  }
  return $str
}

foreach val $vals {
  if {$val eq "UserStartTime"} {
    binary scan [registry get $key $val] ii l h
    puts [format "%s : %s" $val [clock format [expr int( \
       (([format %u $h] << 32 | [format %u $l]) - 116444736 * 1e9) / 1e7 \
      )] -format {%m-%d-%Y %H:%M:%S}]
    ]
  }

  if {$val eq "IconStreams"} {
    puts [format "%s   :" $val]
    foreach rot13v [lsort -unique [ \
       regexp -all -inline {[\x20-\x7E]{39,}} [ \
          encoding convertfrom unicode [registry get $key $val] \
       ] \
    ]] {
      puts [format "%73s" [string range $rot13v 0 38][ \
         rot13 [string range $rot13v 39 [string length $rot13v]]]]
    }
  }
}
