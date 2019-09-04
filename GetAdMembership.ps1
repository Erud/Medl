Get-ADPrincipalGroupMembership pa-trcombs | 
%{Get-ADGroup $_.distinguishedName -Properties DistinguishedName,SamAccountName,Description} |
select SamAccountName,Description,DistinguishedName |
Export-Csv C:\Temp\pa-trcombs.csv -NoTypeInformation
