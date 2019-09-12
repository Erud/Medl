Get-ADComputer -Filter {CN -like "*dhcp*"} -Properties * |
Select CanonicalName,CN,Created,Description,DistinguishedName,Enabled,IPv4Address,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion | 
Export-Csv C:\Temp\allServersDHCP.csv -NoTypeInformation