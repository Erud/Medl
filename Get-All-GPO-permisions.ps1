$AllGPOs = Get-GPO -All
$AllGPOperm = @()
foreach ($GPO in $AllGPOs)

{
	$allPerm =  Get-GPPermissions -Name $GPO.displayname.ToString() -All
	foreach ($perm in $allPerm) {
		$line =[ordered] @{
			"DisplayName" = $GPO.DisplayName
			"Owner" = $GPO.Owner
			"GpoStatus" = $GPO.GpoStatus
			"CreationTime" = $GPO.CreationTime
			"ModificationTime" = $GPO.ModificationTime
			"Trustee" = $perm.Trustee.Name
			"Sid" = $perm.Trustee.Sid
			"TrusteeType" = $perm.Trustee.SidType
			"Permission" = $perm.Permission
			"Denied" = $perm.Denied
			"Inherited" = $perm.Inherited
		}
		$AllGPOperm +=  New-Object -Property $line -TypeName PSObject
	}
}

$AllGPOperm | Export-Csv -Path "c:\temp\GPOperm.csv" -NoTypeInformation