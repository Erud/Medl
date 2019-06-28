#$Cred = Get-Credential 'medline-nt\pa-erudakov'
$servers = Get-Content 'C:\Temp\ECT_to_add_new_local_Adm_serversGroups.txt'
foreach ($server in $servers) {
	$server
	Add-ADGroupMember -Identity "SD-TS-$server-Admin" -Members "RG-Administrators-ECT-Exchange" 
}