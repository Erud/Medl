Get-ADgroup -Filter * -searchbase 'OU=Security,OU=Groups,OU=Special,DC=medline,DC=com' -Properties * |
Export-Csv C:\Temp\groups.csv -NoTypeInformation