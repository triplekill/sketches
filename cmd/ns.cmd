@echo off
  if /i "%~1" equ "" if not defined run goto:box
  setlocal enabledelayedexpansion
    set "argc=-1" % rem : arguments counter
    for %%i in (%*) do set /a "argc+=1"
    if /i "%~1" equ "man" call:man %~2&goto:eof
    if !argc! neq 1 goto:err
    call:%*
  endlocal
exit /b

:err
  echo:[91m=^>err[0m
exit /b

:man
  if !argc! equ 0 (
    for %%i in (
      "%~n0 v1.00 - convert numbers into various number systems"
      "[Enter .c to clear output data or .q to exit]"
      "For hex numbers consisting only of dec numbers use "x" prefix."
      ""
      "Type"
      "   man [hex2bin|hex2dec]"
      "for the details."
    ) do echo:[96m%%~i[0m
  )
  if !argc! equ 1 (
    for /f "delims=:" %%i in (
      'findstr /birc:":%~1" "%~f0"'
    ) do set "#=%%~i"&&echo [96m!#:; rem=-![0m
  )
exit /b

:hex2bin ; rem convert hex to bin and vice versa
  echo:%~1|>nul findstr /irc:"[a-f,x]"&&(
    2>nul (set /a "#=0%~1"||set /a "#=0x%~1")&&(
      for /l %%i in (1,1,32) do (
        set /a "b=#&1, #>>=1"
        set "bin=!b!!bin!"
      )
      set "#=%~1"&set "#=!#:~0,1!"
      for /f "delims=1" %%i in ("!bin!") do echo:%~1 = !bin:%%i=!
    )||goto:err
  )||(
    echo:%~1|>nul findstr /irc:"[2-9a-z]"&&goto:err
    set "bin=%~1"
    for /l %%i in (1,1,32) do (
      if defined bin (
        set /a "#=(#<<1)|!bin:~0,1!"
        set "bin=!bin:~1!"
      )
    )
    cmd /c exit /b !#!&echo:%~1 = 0x!=exitcode!
  )
exit /b

:hex2dec ; rem convert hex to dec and vice versa
  echo:%~1|>nul findstr /irc:"[a-f,x]"&&(
    2>nul (set /a "#=0%~1"||set /a "#=0x%~1")&&echo:%~1 = !#!||goto:err
  )||(
    echo:%~1|>nul findstr /irc:"[g-w,y,z]"&&goto:err
    cmd /c exit /b %~1&echo:%~1 = 0x!=exitcode!
  )
exit /b

:box
  setlocal
    set "run=true"
    :while
      set /p "i=[92m>>>[0m "
      cmd /c "%~f0" %i%
      if /i "%i%" equ ".c" cls
      if /i "%i%" equ ".q" goto:eof
      goto:while
  endlocal
exit /b
