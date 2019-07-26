0</* :
@echo off
  setlocal enabledelayedexpansion
    set "chakra={1b7cd997-e5ff-4932-a7a6-2a9e636da385}"
    if not exist "%comspec:cmd.exe=chakra.dll%" call:err 1
    >nul 2>nul reg query "HKCR\CLSID\%chakra%"||call:err 3
    if %errorlevel% equ -1 goto:eof
    cscript /nologo /e:%chakra% "%~f0" %*
  endlocal
exit /b

:err
  set "err.1=Chakra engine library has not been found."
  set "err.3=Chakra library has not been registered."
  echo:[91m[Error]: !err.%~1![0m
  set "errorlevel=-1"
exit /b*/0;
'use strict';
(function(args) {
  if (1 !== args.length) {
    WScript.echo(`${WScript.ScriptName} - hybrid sketch
    Convert string passed as an argument to the base64.
    For educational purpose only.`);
    return;
  }

  let AsciiRange = (first, total) => {
    return [...Array(parseInt(total)).keys()].map(
      i => String.fromCharCode(i += parseInt(first))
    );
  }, Base64Map = AsciiRange(65, 26).concat(
    AsciiRange(97, 26), AsciiRange(48, 10)
  ).join('') + '+/';

  if (!String.prototype.toBase64) {
    String.prototype.toBase64 = function() {
      let s = this, i = s.length % 3, e = '', r = '';
      if (i > 0) for (; i < 3; i++) { s += "\0"; e += '=' }
      for (i = 0; i < s.length; i += 3) {
        let j = (s.charCodeAt(i) << 16) +
                (s.charCodeAt(i + 1) <<  8) +
                (s.charCodeAt(i + 2));
        r += [j >> 18, j >> 12, j >> 6, j].map(
          j => Base64Map[j &= 63]
        ).join('');
      }

      return r.replace(new RegExp('.{' + e.length + '}$'), e);
    }
  }

  WScript.echo(args(0).toBase64());
}(WScript.Arguments));
