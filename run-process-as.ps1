$ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
$Process = New-Object System.Diagnostics.Process
$user = "pa-erudakov"
$Password = ConvertTo-SecureString -String "" -AsPlainText -Force

#$ProcessInfo.FileName    = "$($env:SystemRoot)\system32\cmdkey.exe"
$ProcessInfo.Username = $user
$ProcessInfo.Domain = "MEDLINE-NT"
$ProcessInfo.Password = $Password

$ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
#$Process.StartInfo = $ProcessInfo

$ProcessInfo.UseShellExecute = $false
$ProcessInfo.FileName    = "$($env:SystemRoot)\system32\mmc.exe"
#$ProcessInfo.Arguments   = "$MstscArguments /v $Computer"
$ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
$Process.StartInfo       = $ProcessInfo


[void]$Process.Start()

#$null = $Process.WaitForExit()

				