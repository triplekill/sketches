using namespace System.Windows.Media

Add-Type -AssemblyName WindowsBase

function fac([UInt16]$x) {$x -le 1 ? 1 : $x * (fac ($x - 1))}
function gcd($x, $y) {[Math]::Abs((.({gcd $y ($x % $y)}, {$x})[!$y]))}
function lcm($x, $y) {[Math]::Abs($x * $y / (gcd $x $y))}

function fib([UInt16]$x) {
  $m1, $m2 = [Matrix]::new(1,0,0,1,0,0), [Matrix]::new(1,1,1,0,0,0)
  for ($i = 1; $i -lt $x; $i++) {$m1 *= $m2}
  $m1.M11
}
