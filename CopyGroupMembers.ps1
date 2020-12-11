$acl=Get-Acl -Path "AD:\cn=wms_inbound_supervisor,ou=security,ou=*groups,ou=medline industries,dc=medline,dc=com"

$ar = $(foreach ($acla in $acl.Access) {
	If(!$acla.IsInherited) { $acla.IdentityReference}
} ) | Sort-Object | Get-Unique

<#
$users = Get-ADGroupMember group_A 
Add-ADGroupMember -Identity group_B -members $users.distinguishedName 
#>