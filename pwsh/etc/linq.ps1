#requires -version 6.1

if (($ta = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys -notcontains 'linq') {
  $ta::Add('linq', [Linq.Enumerable])
}

######################################################################################

Add-Member -InputObject ([Linq] # [Linq].max([..], type)
) -MemberType ScriptMethod -Name max -Value {
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Object[]]$Source,

    [Parameter(Position=1)]
    [ValidateNotNull()]
    [Type]$Type = [Int32]
  )

  process {
    [Linq]::Max($Source -as ("$($Type.Name)[]" -as [Type]))
  }
} -Force

######################################################################################

Add-Member -InputObject ([Linq] # [Linq].min([..], type)
) -MemberType ScriptMethod -Name min -Value {
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Object[]]$Source,

    [Parameter(Position=1)]
    [ValidateNotNull()]
    [Type]$Type = [Int32]
  )

  process {
    [Linq]::Min($Source -as ("$($Type.Name)[]" -as [Type]))
  }
} -Force

######################################################################################

Add-Member -InputObject ([Linq] # [Linq].sub([..], type)
) -MemberType ScriptMethod -Name sub -Value {
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Object[]]$Source,

    [Parameter(Position=1)]
    [ValidateNotNull()]
    [Type]$Type = [Int32]
  )

  process {
    [Linq]::Aggregate(
      $Source, [Func[Object, Object, Object]]{$args[0] - $args[1]}
    ) -as $Type
  }
} -Force

######################################################################################

Add-Member -InputObject ([Linq] # [Linq].sum([..], type)
) -MemberType ScriptMethod -Name sum -Value {
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Object[]]$Source,

    [Parameter(Position=1)]
    [ValidateNotNull()]
    [Type]$Type = [Int32]
  )

  process { [Linq]::Sum($Source -as ("$($Type.Name)[]" -as [Type])) -as $Type }
} -Force

######################################################################################

Add-Member -InputObject ([Linq] # [Linq].zip([..], [..], method=scriptblock)
) -MemberType ScriptMethod -Name zip -Value {
  param(
    [Parameter(Mandatory, Position=0)]
    [ValidateNotNullOrEmpty()]
    [Object[]]$First,

    [Parameter(Mandatory, Position=1)]
    [ValidateNotNullOrEmpty()]
    [Object[]]$Second,

    [Parameter(Mandatory, Position=2)]
    [ValidateNotNullOrEmpty()]
    [ScriptBlock]$Method
  )

  process {
    ($res = [Linq]::Zip(
      $First, $Second, $Method -as [Func[Object, Object, [Object[]]]]
    )).Dispose()
    $res
  }
} -Force
