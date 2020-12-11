$results = @()
$groups = Get-ADGroup -Filter * -SearchBase "OU=Security,OU=*Groups,OU=Medline Industries,DC=medline,DC=Com" -Properties *   
foreach ($group in $groups) {
	#$members = $group | Get-ADGroupMember
	$ldapFilter = '(&(objectclass=user)(objectcategory=person)(memberof:1.2.840.113556.1.4.1941:={0}))' -f $group.DistinguishedName
	$members = Get-ADObject -LDAPFilter $ldapFilter -SearchBase "DC=medline,DC=Com" -ResultSetSize $null -ResultPageSize 1000 -Properties:@('samAccountName')
	$results += New-Object psObject -Property @{'GroupName'=$group;'Members'=$members.count;'GroupCategory'=$group.GroupCategory;'GroupScope'=$group.GroupScope;'info'=$group.info;'Description'=$group.Description;'ManagedBy'=$group.ManagedBy;'Name'=$group.Name;'ObjectClass'=$group.ObjectClass;'ProtectedFromAccidentalDeletion'=$group.ProtectedFromAccidentalDeletion}
	$members = $null
}
$results | Export-Csv C:\Temp\MLSecurityGroups1.csv -NoTypeInformation