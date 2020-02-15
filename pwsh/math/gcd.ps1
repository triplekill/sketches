$function:gcd = {param($x, $y) .({gcd $y ($x%$y)},{$x})[!$y]}
