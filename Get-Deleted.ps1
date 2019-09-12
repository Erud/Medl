Get-ADObject -ldapFilter:"(msDS-LastKnownRDN=*)" –IncludeDeletedObjects

#Get-ADObject -Filter {displayName -eq "testuser3"} IncludeDeletedObjects | Restore-ADObject