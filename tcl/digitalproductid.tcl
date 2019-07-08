if {"Windows NT" != $tcl_platform(os) || "5.1" != $tcl_platform(osVersion)} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion}

if {[catch {set raw [registry get $key DigitalProductId]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

set map [split {BCDFGHJKMPQRTVWXY2346789} {}]
set key [split [string repeat * 29] {}] ; # result storage

binary scan $raw ic4c24ic16c16 sz ver productid keyid editionid cdkey
if {0xA4 != $sz} { ; # the size of value has fixed length
  puts stderr "The size of read data is out of range."
  exit 1
}

puts [format "Product ID  : %s" [binary format c* $productid]]
puts [format "Edition ID  : %s" [binary format c* $editionid]]

for {set i 28} {$i > -1} {incr i -1} {
  if {[expr 0 == ($i + 1) % 6]} {
    set key [lreplace $key $i $i -]
  } else {
    set k 0
    for {set j 14} {$j > -1} {incr j -1} {
      set k [expr ($k * 0x100) ^ ([lindex $cdkey $j] & 0xFF)]
      set cdkey [lreplace $cdkey $j $j [expr $k / 24]]
      set k [expr $k % 24]
      set key [lreplace $key $i $i [lindex $map $k]]
    }
  }
}
puts [format "Product key : %s" [string map {" " ""} $key]]
