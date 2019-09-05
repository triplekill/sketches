#requires -version 6
Set-Alias -Name cal -Value Get-Calendar
function Get-Calendar {
  <#
    .SYNOPSIS
        Display a calendar of the selected month.
    .DESCRIPTION
        `Get-Calendar` (shortly `cal`) just helps to vizualize a month days.
    .PARAMETER Month
        Set a month number. The current month number is set by default.
    .PARAMETER Year
        Set a year number. The current year number is set by default.
    .PARAMETER Invert
        Indicates that the week starts on Monday.
    .PARAMETER Vertical
        Indicates that an alternative layout should be used.
    .INPUTS
        System.Int32 - Month
        System.Int32 - Year
        Other parameters  - System.Management.Automation.SwitchParameter
    .OUTPUTS
        System.Object[]
    .EXAMPLE
        PS C:\> Get-Calendar
        This prints the current month calendar.
    .EXAMPLE
        PS C:\> Get-Calendar -Month 10 -Invert

            October 2019
        Mo Tu We Th Fr Sa Su
            1  2  3  4  5  6
         7  8  9 10 11 12 13
        14 15 16 17 18 19 20
        21 22 23 24 25 26 27
        28 29 30 31
    .EXAMPLE
        PS C:\> Get-Calendar -Vertical -Year 2021

           September 2021
        Su     5 12 19 26
        Mo     6 13 20 27
        Tu     7 14 21 28
        We  1  8 15 22 29
        Th  2  9 16 23 30
        Fr  3 10 17 24
        Sa  4 11 18 25
    .NOTES
        MIT
    .LINK
        None
  #>
  [CmdletBinding()]
  param(
    [Parameter(Position=0)]
    [ValidateRange(1, 12)]
    [Alias('m')]
    [Int32]$Month = ($script:d = Get-Date).Month,

    [Parameter(Position=1)]
    [ValidateRange(1970, 3000)]
    [Alias('y')]
    [Int32]$Year = (.({Get-Date},{$d})[(Test-Path variable:d)]).Year,

    [Parameter()][Alias('i')][Switch]$Invert,
    [Parameter()][Alias('v')][Switch]$Vertical
  )

  begin {
    $day = "$($d.Day)".PadLeft(2, [Char]32)
    $raw, $dfi = $host.UI.RawUI, (Get-Culture en-US).DateTimeFormat
    $arr, $cal = $dfi.ShortestDayNames, $dfi.Calendar

    $dow = [Int32]$cal.GetDayOfWeek("$Month.1.$Year")
    if ($Invert) {
      $arr = $arr[1..$arr.Length] + $arr[0]
      if (($dow = --$dow) -lt 0) { $dow += 7 }
    }
  }
  process {
    $cap = "`e[35;1m$($dfi.MonthNames[$Month - 1]) $Year`e[32;0m"
    $cap = "$([Char]32)" * [Math]::Round((34 - $cap.Length) / 2) + $cap

    if ($dow -ne 0) { for ($i = 0; $i -lt $dow; $i++) {
      $arr += "$([Char]32)" * 2
    }}
    $arr += (1..$cal.GetDaysInMonth($Year, $Month)).ForEach{
      "$_".PadLeft(2, [Char]32)
    }
  }
  end {
    $cap
    .({
      $i = 0
      $seq = (,7 * 6).ForEach{$_ * (++$i)}
      for ($i = 0; $i -lt 7; $i++) {
        if (($itm = $arr[,$i + $seq]) -contains $day) {
          $cur, $pos = $raw.CursorPosition, $itm
        }
        $itm -join [Char]32
        $seq = $seq.ForEach{$_ + 1}
      }
    },{
      for ($i = 0; $i -lt $arr.Length; $i += 6) {
        if (($itm = $arr[$i..($i + 6)]) -contains $day) {
          $cur, $pos = $raw.CursorPosition, $itm
        }
        $itm -join [Char]32
        $i++
      }
    })[!$Vertical]
    if ($Month -ne $d.Month -or $Year -ne $d.Year) { return }
    $cur.X = ($x = $pos.IndexOf($day)) * 2 + $x
    $raw.SetBufferContents($cur, $raw.NewBufferCellArray(
      $day, [ConsoleColor]::Black, [ConsoleColor]::White
    ))
  }
}
