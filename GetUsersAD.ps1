# Import the AD module to the session

Import-Module ActiveDirectory

#Search for the users and export report

get-aduser -filter * -properties Name, PasswordNeverExpires | where {($_.passwordNeverExpires -eq "true") -and ($_.sAMAccountName -like 'pa-*') } |  Select-Object DistinguishedName,Name,sAMAccountName,Enabled |
Export-csv c:\temp\pw_never_expires.csv -NoTypeInformation