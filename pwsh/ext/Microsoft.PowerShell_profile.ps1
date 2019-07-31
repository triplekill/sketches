#requires -version 6
Set-PSReadlineOption -HistoryNoDuplicates
Set-Content function:prompt -Value @'
"`n`e[32;1m$(
  $ExecutionContext.SessionState.Path.CurrentLocation
) `e[35;4m$(
  if (Test-Path .git\HEAD) {
    if (($$ = ( # check record of the current branch
      Select-String '^ref:.*/(.*)$' .git\HEAD
    ).Matches.Groups[1].Value)) { "($($$))" }
  }
)`e[0m`n`e[36;1m[$(
  if (!( # show command number
    $lastCmdInfo = Get-History -Count 1
  )) {1} else { $lastCmdInfo.Id + 1}
)] `e[33;1m$(
  "`u{3bb}" *($NestedPromptLevel + 1)
)`e[0m`e[0 q`e[?12l "
'@

if ($IsLinux) {
  Register-EngineEvent PowerShell.Exiting -Action {
    find /tmp/ -type s -name '*.pwsh' -delete
  } | Out-Null
}
