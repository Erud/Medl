#Get-ADComputer -Filter {CN -like "*dhcp*"} -Properties * |
Get-ADComputer -Filter {OperatingSystem -like "*server*"} -Properties * |
Select CanonicalName,CN,Created,Description,DistinguishedName,Enabled,IPv4Address,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion | 
Export-Csv C:\Temp\allServers.csv -NoTypeInformation