@echo off
  if /i "%~1" equ "" if not defined run goto:box
  setlocal enabledelayedexpansion
    set "i=0"
    for %%i in (%*) do set /a "i+=1"
    if !i! neq 1 goto:err

    echo:%~1|>nul findstr /irc:"[a-f,x]"&&(
      2>nul (set /a "num=0%~1"||set /a "num=0x%~1")&&echo:%~1 = !num!||goto:err
    )||(
      echo:%~1|>nul findstr /irc:"[g-w,y,z]"&&goto:err
      cmd /c exit /b %~1&echo:%~1 = 0x!=exitcode!
    )
  endlocal
exit /b

:err
  echo:[91m=^>err[0m
exit /b

:box
  for %%i in (
    "%~n0 v1.05 - convert hex to decimal and vice versa"
    "[Enter .c to clear output data or .q to exit]"
    "For hex numbers consisting only of dec numbers use "x" prefix."
    ""
  ) do echo:[92m%%~i[0m
  setlocal
    set "run=true"
    :repeat
      set /p "i=[92m>>>[0m "
      cmd /c "%~f0" %i%
      if /i "%i%" equ ".c" cls
      if /i "%i%" equ ".q" goto:eof
      goto:repeat
  endlocal
exit /b
