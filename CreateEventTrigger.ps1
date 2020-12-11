<#$ActionParameters = @{
	Execute  = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'
	Argument = '-NoProfile -File C:\scripts\NetworkConnectionCheck.ps1'
}#>

<#
Id               : 
Arguments        : 
Execute          : C:\Temp\test.bat
WorkingDirectory : 
PSComputerName   : 
#>
$ActionParameters = @{
	Execute  = 'C:\Windows\System32\LoginVPN.bat'
}#>

$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler

$trigger = $class | New-CimInstance -ClientOnly
$trigger.Enabled = $false
$trigger.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=10000]]</Select></Query></QueryList>'

$Action = New-ScheduledTaskAction @ActionParameters
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet

$RegSchTaskParameters = @{
	TaskName    = 'Run VPN Logon batch'
	Description = 'runs at network connection'
	TaskPath    = '\Event Viewer Tasks\'
	Action      = $Action
	Principal   = $Principal
	Settings    = $Settings
	Trigger     = $Trigger
}

$tenp = Register-ScheduledTask @RegSchTaskParameters