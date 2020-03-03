#Change my.user with the target user account.
$username = "pa-erudakov"
#This command will get the current PwdLastSet value.
$User = Get-ADUser $username  -properties pwdlastset
#Display the current password last set date (convert date to human readable):
[datetime]::fromFileTime($user.pwdlastset)
#Change the user's pwdlastset attribute to 0
$User.pwdlastset = 0
#Apply the changes against the object
Set-ADUser -Instance $User
#Change the user's pwdlastset attribute to -1
$user.pwdlastset = -1
#Apply the changes against the object
Set-ADUser -instance $User
#Read again the value from AD
$User = Get-ADUser $username  -properties pwdlastset
#Current password last set date, it should be displaying today (convert date to human readable):
[datetime]::fromFileTime($user.pwdlastset)