### Variables
$dropboxDBfile = Get-ChildItem -Path $env:USERPROFILE\AppData\Local -Recurse -ErrorAction SilentlyContinue | ? {$_.Name -eq 'host.db'}
$base64path = gc $dropboxDBfile.FullName | select -index 1
$dropboxPath = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($base64path)) # convert from base64 to ascii

$taskName = "Keep_WiFi_Connected"
$Path = 'PowerShell.exe'
$Arguments = "$dropboxPath\request\Scripts\Hire\NetworkConnections\StartLTE-WiFi.ps1"

$Service = new-object -ComObject ("Schedule.Service")
$Service.Connect()
$RootFolder = $Service.GetFolder("\")
$TaskDefinition = $Service.NewTask(0) # TaskDefinition object https://msdn.microsoft.com/en-us/library/windows/desktop/aa382542(v=vs.85).aspx
$TaskDefinition.RegistrationInfo.Description = ''
$TaskDefinition.Settings.Enabled = $True
$TaskDefinition.Settings.AllowDemandStart = $True
$TaskDefinition.Settings.DisallowStartIfOnBatteries = $False
$Triggers = $TaskDefinition.Triggers
$Trigger = $Triggers.Create(0) ## 0 is an event trigger https://msdn.microsoft.com/en-us/library/windows/desktop/aa383898(v=vs.85).aspx
$Trigger.Enabled = $true
$TaskEndTime = [datetime]::Now.AddMinutes(30);$Trigger.EndBoundary = $TaskEndTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
$Trigger.Id = '8003' # 8003 is for disconnections and 8001 is for connections
$Trigger.Subscription = "<QueryList><Query Id='0' Path='Microsoft-Windows-WLAN-AutoConfig/Operational'><Select Path='Microsoft-Windows-WLAN-AutoConfig/Operational'>*[System[Provider[@Name='Microsoft-Windows-WLAN-AutoConfig'] and EventID=8003]]</Select></Query></QueryList>"
$Action = $TaskDefinition.Actions.Create(0)
$Action.Path = $Path
$action.Arguments = $Arguments
$RootFolder.RegisterTaskDefinition($taskName, $TaskDefinition, 6, "System", $null, 5) | Out-Null