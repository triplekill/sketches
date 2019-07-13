#requires -version 6.1

Add-Member -InputObject ([String] # [String].bin('...', [encoding, decode=bool])
) -MemberType ScriptMethod -Name bin -Value {
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$String,

    [Parameter()]
    [ValidateSet('ASCII',
                 'BigEndianUnicode',
                 'Default',
                 'Unicode',
                 'UTF32',
                 'UTF7',
                 'UTF8')]
    [String]$Encoding = 'Default',

    [Parameter()]
    [Switch]$Decode
  )

  process {
    .({-join[Text.Encoding]::$Encoding.GetBytes($String).ForEach{
      [Convert]::ToString($_, 2).PadLeft(8, '0')
    }},{[Text.Encoding]::$encoding.GetString(
      ($String -split '(.{8})').Where{$_}.ForEach{
        [Convert]::ToByte($_, 2)
      })
    })[!!$Decode]
  }
} -Force

######################################################################################

Add-Member -InputObject ([String] # [String].ent('...')
) -MemberType ScriptMethod -Name ent -Value {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$String
  )

  process {
    (([Char[]]$String | Group-Object).ForEach{
      -($e = $_.Count / $String.Length) * [Math]::Log($e, 2)
    } | Measure-Object -Sum).Sum.ToString('f3')
  }
} -Force

######################################################################################

Add-Member -InputObject ([String] # [String].rev('...')
) -MemberType ScriptMethod -Name rev -Value {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$String
  )

  process {
    ($res = [Linq.Enumerable]::Reverse($String)).Dispose()
    -join$res
  }
} -Force

######################################################################################

Add-Member -InputObject ([String] # [String].rot13('...')
) -MemberType ScriptMethod -Name rot13 -Value {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$String
  )

  process {
    $top, $low = (65..77 + 97..109), (78..90 + 110..122)
    -join ([Char[]]$String).ForEach{
      $c = [Int32]$_
      [Char]$(if ($c -in $top) { $c + 13 }
      elseif ($c -in $low) { $c - 13}
      else { $c })
    }
  }
} -Force
