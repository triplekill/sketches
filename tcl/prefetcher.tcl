if {"windows nt" != [string tolower $tcl_platform(os)]} {
  throw {OSERROR} {Wrong operating system.}
}

package require registry

if 0 {
  set HKLM {HKEY_LOCAL_MACHINE}
  set key  {SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters}

  set status [
     dict create 0 {disabled} \
                 1 {enabled for applications} \
                 2 {enabled for boot only} \
                 3 {enabled for boot and applications} \
  ]

  proc getstatus {value item} {
    global HKLM key status
    if {[catch {set tmp [registry get "$HKLM\\$key" $value]} e]} {
      puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
      exit 1
    }
    puts "$item is [dict get $status $tmp]."
  }

  getstatus EnablePrefetcher Prefetcher
  getstatus EnableSuperfetch Superfetch
}

set key {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control}
set key [format "%s\\%s" $key {Session Manager\Memory Management\PrefetchParameters}]

if {[catch {set vals [registry values $key]} e]} {
  puts stderr [format "\[Error\]: %s" [lindex [split $e :] 0]]
  exit 1
}

set startup {Disabled Application BootUp AppAndBootUp}
foreach val $vals {
  if {[string match -nocase enable* $val]} {
    puts [format "%s: %s" \
      [regsub -nocase {enable} $val {\1}] [lindex $startup [registry get $key $val]]
    ]
  }
}
