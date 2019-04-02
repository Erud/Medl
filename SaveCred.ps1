#read-host -assecurestring | convertfrom-securestring | out-file C:\temp\username-password-encrypted.txt
$username = "medline-nt\pa-erudakov"
$password = cat C:\temp\username-password-encrypted.txt | convertto-securestring
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

$Server01 = New-PSSession -ComputerName MUNPRDATG1 -Credential $cred
