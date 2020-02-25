Import-Module ActiveDirectory
$rootdse = Get-ADRootDSE
$domain = Get-ADDomain

$group = 'CN=ECM_Scanner,OU=OnBase_ECM,OU=Security,OU=Groups,OU=Special,DC=medline,DC=com'
$OU = 'OU=OnBase_ECM,OU=Security,OU=Groups,OU=Special,DC=medline,DC=com'


$gacl = (Get-Acl -path ("AD:\"+(Get-ADGroup $group).DistinguishedName)).access | ft identityreference, accesscontroltype, IsInherited -AutoSize

Get-ChildItem -Path "AD:\"+(Get-ADGroup $OU).DistinguishedName