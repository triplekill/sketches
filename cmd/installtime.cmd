@echo off
  setlocal
    set key="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
    for /f "tokens=3" %%i in (
      '2^>nul reg query %key% /v InstallTime ^| findstr /rc:"^[ ]"'
    ) do set "#=%%i"

    if "%#%" equ "" (
      echo:Required parameter has not been found.
      goto:eof
    ) else (
      for /f "tokens=2 delims=-" %%i in ('w32tm /ntte %#%') do (
        echo:OS install date%%~i.
      )
    )
  endlocal
exit /b
