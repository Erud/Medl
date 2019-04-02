
$groups = Get-Content C:\Temp\groups.txt
$allmembers = $null
foreach($group in $groups){
    $members= $null
	$members = Get-ADGroupMember -Identity $group -Recursive
    $group
	$allmembers += $members
	$members | Get-ADUser |
	select distinguishedName,SamAccountName,Name,UserPrincipalName,enabled,LockedOut,passwordneverexpires |
	Export-Excel -Path C:\Temp\groups.xlsx -WorksheetName $group 
} 
$allmembers | Export-Excel -Path C:\Temp\groups.xlsx -WorksheetName "AllMembers"