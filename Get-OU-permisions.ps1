$RootDSE = Get-ADRootDSE
$Schema_DN = $RootDSE.schemaNamingContext
$ExtendedRights_DN = "CN=Extended-Rights,$($RootDSE.configurationNamingContext)"

$GUID_Htabl = @{}
Get-ADObject -SearchBase $Schema_DN -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID |
    Sort-Object name | 
    ForEach-Object { $GUID_Htabl.Add($_.Name,[GUID]$_.schemaIDGUID) } |
Get-ADObject -SearchBase $ExtendedRights_DN -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID |
    Sort-Object name |
    ForEach-Object { $GUID_Htabl.Add($_.Name,[GUID]$_.rightsGUID) }

$ACL.Access |
Select-Object accessControlType,
              activeDirectoryRights,
              identityReference,
              inheritanceFlags,
              inheritanceType,
              isInherited,
              objectFlags,
              propagationFlags,
              objectType,
              @{ n = 'objectTypeName'; e =
                {
                    if ($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000')
                    { 'All' }
                    else
                    { $oT = $_.objectType; @(($GUID_Htabl.GetEnumerator() | Where-Object { $_.Value -eq $oT }).Name)[0] }
                }
               },
               inheritedObjectType,
              @{ n = 'inheritedObjectTypeName' ; e =
                { 
                    if ($_.inheritedobjectType.ToString() -eq '00000000-0000-0000-0000-000000000000')
                    { 'None' }
                    else
                    { $iOT = $_.inheritedObjectType; @(($GUID_Htabl.GetEnumerator() | Where-Object { $_.Value -eq $iOT }).Name)[0] }
                }
               }