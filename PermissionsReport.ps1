#-----------------------------------------------------------------------------
#Source references
#-----------------------------------------------------------------------------
#Preventing Unwanted/Accidental deletions and Restore deleted objects in Active Directory
#abizer_hazratJune 9, 2009
#https://blogs.technet.microsoft.com/abizerh/2009/06/09/preventing-unwantedaccidental-deletions-and-restore-deleted-objects-in-active-directory/
#Windows Server 2008 Protection from Accidental Deletion
#James ONeill, October 31, 2007
#https://blogs.technet.microsoft.com/industry_insiders/2007/10/31/windows-server-2008-protection-from-accidental-deletion/
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#initialisation
#-----------------------------------------------------------------------------

#the CSV file is saved in the same directory as the PS file

$csvFile = $MyInvocation.MyCommand.Definition -replace 'ps1','csv'
$report = @()
#(*) Credits 
$schemaIDGUID = @{}
### NEED TO RECONCILE THE CONFLICTS ###
$ErrorActionPreference = 'SilentlyContinue'
Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID |
 ForEach-Object {$schemaIDGUID.add([System.GUID]$_.schemaIDGUID,$_.name)}
Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID |
 ForEach-Object {$schemaIDGUID.add([System.GUID]$_.rightsGUID,$_.name)}
$ErrorActionPreference = 'Continue'

#(*)
#----------------------------------------------------------------------------
#Functions
#----------------------------------------------------------------------------
function CheckProtection
{
    param($obj)
    $path = "AD:\" + $obj
    Get-Acl -Path $path | `
    Select-Object -ExpandProperty Access | `
    Where-Object {($_.ActiveDirectoryRights -like "*DeleteTree*") -AND ($_.AccessControlType -eq "Deny")} | `

        #(*)
        Select-Object @{name='Object';expression={$obj}}, `
        @{name='objectTypeName';expression={if ($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') {'All'} Else {$schemaIDGUID.Item($_.objectType)}}}, `
        @{name='inheritedObjectTypeName';expression={$schemaIDGUID.Item($_.inheritedObjectType)}}, `
        #(*)

        ActiveDirectoryRights,
        ObjectFlags,
        AccessControlType,
        IdentityReference,
        Isnherited,
        InheritanceFlags,
        PropagationFlags
}

#-----------------------------------------------------------------------------
#MAIN
#-----------------------------------------------------------------------------
#add the top domain
$OUs = @(Get-ADDomain | Select-Object -ExpandProperty DistinguishedName)
#add the OUs
$OUs += Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
#add other containers
$OUs += Get-ADObject -SearchBase (Get-ADDomain).DistinguishedName -LDAPFilter '(|(objectClass=container)(objectClass=builtinDomain))' | Select-Object -ExpandProperty DistinguishedName
#if you don't want to scan the builtin container use line below instead of line above
#$OUs += Get-ADObject -SearchBase (Get-ADDomain).DistinguishedName -LDAPFilter '(objectClass=container)' | Select-Object -ExpandProperty DistinguishedName
#set the target objects types to investigate
#including users, groups, contacts, computers
$ldapfilter = '(|(objectclass=user)(objectclass=group)(objectclass=contact)(objectclass=computer))'
#$ldapfilter = '(|(objectclass=user)(objectclass=group)(objectclass=contact)(objectclass=computer)(objectclass=Foreign-Security-Principal))'
#not included: Foreign-Security-Principal, msTPM-InformationObjectsContainer, msDS-QuotaContainer, lostAndFound,

ForEach ($OU in $OUs) 

{
    #check the protection of the parent container
    $isProtected = ''
    $isProtected = CheckProtection $OU

    if ($isProtected -ne $null) {$report += $isProtected}
    
    #Lookup the child target objects in the parent container
    $objects = Get-ADObject -SearchBase $OU -SearchScope OneLevel -LDAPFilter $ldapfilter | Select-Object -ExpandProperty DistinguishedName
    #check the protection of the child objects
    ForEach ($object in $objects)
    {
        $isProtected = ''
        $isProtected = CheckProtection $object
        if ($isProtected -ne $null) {$report += $isProtected}
    }
}
$report | Format-Table -Wrap
$report | Export-Csv -Path $csvFile -NoTypeInformation