$results = @()
$groups = Get-ADGroup -Filter * -SearchBase "OU=Medline Industries,DC=medline,DC=Com"   
foreach ($group in $groups) {
	#$members = $group | Get-ADGroupMember
	$ldapFilter = '(&(objectclass=user)(objectcategory=person)(memberof:1.2.840.113556.1.4.1941:={0}))' -f $group.DistinguishedName
	$members = Get-ADObject -LDAPFilter $ldapFilter -SearchBase "DC=medline,DC=Com" -ResultSetSize $null -ResultPageSize 1000 -Properties:@('samAccountName')
	$results += New-Object psObject -Property @{'GroupName'=$group;'Members'=$members.count}
	$members = $null
}
$results | Export-Csv C:\Temp\MLgroups1.csv -NoTypeInformation