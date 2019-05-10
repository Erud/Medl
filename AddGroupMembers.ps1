$users = Import-CSV C:\temp\users.csv
$group = "RD-ECOM-DEV-Users" 
$cred = Get-Credential 'pa-erudakov'
foreach ($user in $users){
	$user.SamAccountName
	# get-aduser $user.SamAccountName | 
	Add-ADGroupMember $group -Members $user.SamAccountName -Credential $cred 
}