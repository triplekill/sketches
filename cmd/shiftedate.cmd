@echo off
  setlocal enabledelayedexpansion
    set "i=0" % rem : arguments counter
    for %%i in (%*) do set /a "i+=1"
    if !i! neq 1 echo:Index is out of range.&goto:eof
    call:getShiftedDate %~1
  endlocal
exit /b

:getShiftedDate
  set key="HKCU\Control Panel\International"
  for /f "tokens=3*" %%i in (
    'reg query %key% /v sShortDate'
  ) do set "fmt=%%~i" % rem : not all cultures can be parsed
  set "res=!fmt!" % rem : result format
  set "i=0" % rem : indexer of map
  :while
    if defined fmt (
      set "arr.!i!=!fmt:~0,1!" % rem : chars map
      set "fmt=!fmt:~1!" % rem : cut first char
      set /a "i+=1"
      goto:while
    )
  for %%i in (d m y) do (
    set "i=0" % rem : length of the chunk
    set "%%~i=~"
    for /f "tokens=2 delims=.=" %%j in (
      'set arr ^| findstr /irc:"%%~i"'
    ) do (
      set "%%~i=!%%~i!%%~j,"
      set /a "i+=1"
    )
    set "x=!%%~i!"&set "%%~i=!x:~0,3!!i!"
  )
  set /a "d=1!date:%d%!-100, m=1!date:%m%!-100, y=!date:%y%!"
  call:toJulianDay !d! !m! !y!
  set /a "jdn=!jdn!+%~1"
  call:fromJulianDay
exit /b

:toJulianDay
  set "jdn=(1461*(%3+4800+(%2-14)/12))/4+(367*(%2-2-12*((%2-14)/12"
  set "jdn=!jdn!)))/12-(3*((%3+4900+(%2-14)/12)/100))/4+%1-32075"
  set /a "jdn=!jdn!"
exit /b

:fromJulianDay
  set /a "a=jdn+32044, b=(4*a+3)/146097, c=a-146097*b/4"
  set /a "d=(4*c+3)/1461, e=c-1461*d/4, m=(5*e+2)/153"
  set /a "dd=e-(153*m+2)/5+1, mm=m+3-12*(m/10), yyyy=100*b+d-4800+m/10"
  for %%i in (dd mm) do if !%%~i! lss 10 set "%%~i=0!%%~i!"
  for /f "tokens=3" %%i in ('reg query %key% /v sDate') do set "s=%%~i"
  for /f "tokens=1,2,3 delims=%s%" %%i in ("!res!") do (
    echo:!%%~i!!s!!%%~j!!s!!%%~k!
  )
exit /b
