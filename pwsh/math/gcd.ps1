$function:gcd = {param($x, $y) [Math]::Abs((.({gcd $y ($x%$y)},{$x})[!$y]))}
