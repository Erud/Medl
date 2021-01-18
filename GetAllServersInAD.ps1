Get-ADComputer -Filter { OperatingSystem -Like '*Server*'}  -SearchBase 'DC=centurionmp,DC=com' -Properties * -Server centurionmp.com |
#Get-ADComputer -Filter { OperatingSystem -Like '*Server*'}  -SearchBase 'OU=ISTesting,DC=phsyes,DC=com' -Properties * -Server phsyes.com |
#Get-ADComputer -Filter { OperatingSystem -Like '*Server*'}  -SearchBase 'CN=Computers,DC=medline,DC=com' -Properties * |
#Get-ADComputer -Filter *  -SearchBase 'CN=Computers,DC=medline,DC=com' -Properties * |
#where {($_.CN -like '*TST*') -or ($_.CN -like '*TEST*')} |
#Get-ADComputer -Filter {(OperatingSystem -Like '*Server*') -and (CN -Like '*AZ*') }  -SearchBase 'DC=medline,DC=com' -Properties * |
sort DNSHostname |
Select CN, Created,LastLogonDate,@{name ="pwdLastSet"; expression={[datetime]::FromFileTime($_.pwdLastSet)}},Description,DistinguishedName,Enabled, IPv4Address,OperatingSystem,ManagedBy   | 

Export-Csv -Path "C:\Temp\Servers move to OU\ADServers-centurion.csv" -NoTypeInformation
#Export-Csv -Path "C:\Temp\Servers move to OU\ADServers-medlineComp.csv" -NoTypeInformation 

# -Append