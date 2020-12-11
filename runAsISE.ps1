# variables
$mmc = "$($env:SystemDrive)\Windows\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe"
# credentials
$password = get-content C:\temp\cred.txt | convertto-securestring
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "medline-nt\pa-erudakov",$password
# call MMC
Start-Process PowerShell.exe -Credential $cred -ArgumentList "Start-Process -FilePath $mmc -Verb runAs"