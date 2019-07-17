#requires -version 6.1

if (($ta = [PSObject].Assembly.GetType(
  'System.Management.Automation.TypeAccelerators'
))::Get.Keys -notcontains 'linq') {
  $ta::Add('linq', [Linq.Enumerable])
}

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
      $First, $Second, $Method -as [func[Object, Object, [Object[]]]]
    )).Dispose()
    $res
  }
} -Force
