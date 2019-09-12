$servers = Get-Content C:\temp\NeptGServers.txt
$group = "RG-IS-Neptune-Admins" 
$cred = Get-Credential 'pa-erudakov'
foreach ($server in $servers){
	$servergroup = "SD-TS-$server-Admin"  
	# get-aduser $user.SamAccountName | 
	Add-ADGroupMember $servergroup -Members $group -Credential $cred 
}