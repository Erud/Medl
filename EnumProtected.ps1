# enum protected users groups contacts ou
Get-ADUser -Filter {Name -like "*"} -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $true} |
Export-Csv C:\Temp/users_protected.csv -NoTypeInformation 

Get-ADGroup -Filter {Name -like "*"} -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $true} |
Export-Csv C:\Temp/groups_protected.csv -NoTypeInformation 

Get-ADObject -LDAPFilter "(objectClass=contact)" -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $true} |
Export-Csv C:\Temp/contacts_protected.csv -NoTypeInformation 

Get-ADObject -LDAPFilter "(objectClass=organizationalUnit)" -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $true} |
Export-Csv C:\Temp/OUs_protected.csv -NoTypeInformation

Get-ADObject -LDAPFilter "(objectClass=container)" -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $true} |
Export-Csv C:\Temp/containers_protected.csv -NoTypeInformation

Get-ADComputer -Filter {Name -like "*"} -Properties ProtectedFromAccidentalDeletion | where {$_.ProtectedFromAccidentalDeletion -eq $true} |
Export-Csv C:\Temp/computers_protected.csv -NoTypeInformation