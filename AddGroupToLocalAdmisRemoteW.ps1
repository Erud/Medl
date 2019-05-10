$comp = $env:COMPUTERNAME

$Domain = $env:userdomain

$ServerAdminGroup = "$Computername-Admins"



([adsi]"WinNT://./Administrators,group").ADD("WinNT://$domain/$ServerAdminGroup")