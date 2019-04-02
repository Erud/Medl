$users = Get-Content C:\Temp\users.txt
$allusers = @()
foreach($user in $users){
$alluser = Get-ADUser -Identity $user -Properties SamAccountName, DisplayName, Title, DistinguishedName, PasswordNeverExpires, CannotChangePassword, LockedOut, Enabled
$allusers += $alluser
} 
$allusers | Export-Excel -Path C:\Temp\users.xlsx -WorksheetName "Allusers"