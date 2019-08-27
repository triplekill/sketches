@echo off
  setlocal enabledelayedexpansion
    set "key=HKLM\SOFTWARE\Microsoft\RADAR\HeapLeakDetection"
    set "key=%key%\DiagnosedApplications"
    for /f "tokens=3,7 delims=\ " %%i in (
      '2^>nul reg query %key% /s /v LastDetectionTime'
    ) do (
      if /i "%%~j" neq "" call:printf 37 %%j
      if /i "%%~i" neq "microsoft" (
        for /f "tokens=2 delims=-" %%i in (
          'w32tm /ntte %%i'
        ) do echo:%%i
      )
    )
  endlocal
exit /b

:printf
  set "i=%~1" % rem : spaces counter
  set "s=%~2" % rem : input string
  :while
    set "s=!s:~1!"
    if defined s set /a "i-=1"&goto:while
  set "s=%~2" % rem : adding spaces
  for /l %%i in (1,1,!i!) do set "s=!s! "
  <nul set /p "=!s!"
exit /b
