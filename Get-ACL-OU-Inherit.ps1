$OUs = get-content C:\temp\allOUr.txt
Import-Module ActiveDirectory
foreach ($Identity in $OUs) {
	try {
		$oADObject = Get-ADObject -Filter { (Name -eq $Identity) -or (DistinguishedName -eq $Identity) };
		$oAceObj   = Get-Acl -Path ("ActiveDirectory:://RootDSE/" + $oADObject.DistinguishedName);
	} catch {
		Write-Error "Failed to find the source object.";
		return;
	}
	
	if($oAceObj.AreAccessRulesProtected){$Identity}
    #second parameter indicates if you want to save existing rules
    #$acl.SetAccessRuleProtection($False,$True)
    #set-acl
}