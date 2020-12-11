# variables
$mmc = "$($env:SystemDrive)\Windows\System32\mmc.exe"
$msc = "$($env:SystemDrive)\Windows\System32\gpmc.msc"
# credentials
$password = get-content C:\temp\cred.txt | convertto-securestring
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "medline-nt\pa-erudakov",$password
# call MMC
Start-Process powershell.exe -Credential $cred -ArgumentList "Start-Process -FilePath $mmc -ArgumentList $msc -Verb runAs"