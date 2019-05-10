#Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
$cred = Get-Credential -UserName 'pa-erudakov'
$vCenters = "munprdvc1.medline.com, MUNPRDHVIEWVC1.medline.com"

# pause wait 
Function pause ($message) {
	# Check if running Powershell ISE
	if ($psISE) {
		Add-Type -AssemblyName System.Windows.Forms
		[System.Windows.Forms.MessageBox]::Show("$message")
	}
	else {
		Write-Host "$message" -ForegroundColor Yellow
		$x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	}
}


#Connect to our vCenter Server using the logged in credentials
Connect-VIServer $vCenters -Credential $cred
$VMnames = Get-Content C:\Temp\servE.txt #get VM names
foreach ($vmname in $VMnames) { 
	#Get a list of Virtual Machines
	Get-VM $vmname |​​ Open-VMConsoleWindow​​ -FullScreen
	pause "To continue press any key"
}

Disconnect-VIServer​​ $vCenters