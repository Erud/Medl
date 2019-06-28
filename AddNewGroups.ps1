#$Cred = Get-Credential 'medline-nt\pa-erudakov'
$servers = Get-Content 'C:\Temp\ECT_to_add_new_local_Adm_serversGroups.txt'
foreach ($server in $servers) {
	$server
	New-ADGroup -Name "SD-TS-$server-Admin" -SamAccountName "SD-TS-$server-Admin" -GroupCategory Security -GroupScope "DomainLocal" -DisplayName "SD-TS-$server-Admin" -Path "OU=Terminal Services or RDP,OU=Security,OU=Groups,OU=Special,DC=medline,DC=com" -Description "Local Administrators for server $server"
}