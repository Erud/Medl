
$OUs = get-content C:\temp\allOUrO.txt

$Owner = "SD-Administration-OnBase_ECM"
foreach ($Identity in $OUs) {
	$Identity
	try {
		$oADObject = Get-ADObject -Filter { (Name -eq $Identity) -or (DistinguishedName -eq $Identity) };
		$oAceObj   = Get-Acl -Path ("ActiveDirectory:://RootDSE/" + $oADObject.DistinguishedName);
	} catch {
		Write-Error "Failed to find the source object.";
		return;
	}
	
	try {
		$oADOwner   = Get-ADObject -Filter { (Name -eq $Owner) -or (DistinguishedName -eq $Owner) };
		$oNewOwnAce = New-Object System.Security.Principal.NTAccount($oADOwner.Name);
	} catch {
		Write-Error "Failed to find the new owner object.";
		return;
	}
	
	try {
		$oAceObj.SetOwner($oNewOwnAce);
		Set-Acl -Path ("ActiveDirectory:://RootDSE/" + $oADObject.DistinguishedName) -AclObject $oAceObj;
	} catch {
		$errMsg = "Failed to set the new new ACE on " + $oADObject.Name;
		Write-Error $errMsg;
	}
	
}