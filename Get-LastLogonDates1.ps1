$List = @() #Define Array 
$users = Get-Content C:\Temp\usersDA.txt
$dcs = (Get-ADDomain).ReplicaDirectoryServers | Sort 
foreach ($user in $users) {
	if ($user.Length -gt 0) {		
		foreach ($dc in $dcs) {
			if ($dc.Substring(0,9) -ne "PUNPRDDC0"){	
				$List += Get-ADUser -Server $dc -Filter "samaccountname -like '$user'" -Properties LastLogon | Select samaccountname,lastlogon,@{n='DC';e={$DC}} 	
			} 
		}
	}
}

$LatestLogOn = @() 
$List | Group-Object -Property samaccountname | % { 
	
	$LatestLogOn += ($_.Group | Sort -prop lastlogon -Descending)[0] 
	
} 

$LatestLogOn | Select samaccountname, lastlogon, @{n='lastlogondatetime';e={[datetime]::FromFileTime($_.lastlogon)}}, DC | Export-CSV -Path C:\Temp\usersDA.csv -NoTypeInformation -Force