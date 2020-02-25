Param (
[parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)][string]$Identity,
[parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true)][string]$Owner
)

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

.\Set-ADOwner.ps1 testsetsetset SD-Administration-OnBase_ECM