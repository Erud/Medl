$comp = Get-ADComputer MUNPRDDC01 -Properties *
$comp.OperatingSystem
Get-ADComputer -Filter 'OperatingSystem -like "Windows Server*"'
Get-ADComputer -Filter 'Name -like "*PRDDC*"'
Get-ADComputer -Filter 'Name -notlike "*PRDDC*"'

$ADDCs = Get-ADComputer -Filter 'Name -like "*PRDDC*"' | select DNSHostName | Sort-Object

$ADDCs = Get-ADComputer -Filter {(Name -notlike "*PRD*") -and (OperatingSystem -like "Windows Server*")} | select DNSHostName,DistinguishedName,Enabled | Sort-Object <# not prod windows servers#>

$ADDCs | Export-Csv C:\Temp\nonprodWinServers.csv -NoTypeInformation