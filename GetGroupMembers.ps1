
$groups = Get-Content C:\Temp\Agroups.txt
$allmembers = $null
foreach($group in $groups){
	$members= $null
	try {
		$members = Get-ADGroupMember -Identity $group -Recursive
	} 
	catch {
		Write-Host "Unable to obtain members for $group"
	}
	$group
	$allmembers += $members
	$members | Get-ADUser |
	select distinguishedName,SamAccountName,Name,UserPrincipalName,enabled,LockedOut,passwordneverexpires |
	Export-Excel -Path C:\Temp\groups.xlsx -WorksheetName $group 
} 
$allmembers | Export-Excel -Path C:\Temp\aAagroups.xlsx -WorksheetName "AllMembers"