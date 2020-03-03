$name = "W1"
$computers = get-content "c:\temp\$name.txt"
foreach ($comp in $computers) {
	$comp
	if (Test-Path k:) {
		Remove-PSDrive -Name "K" -Force
	}
	
	$password = get-content C:\temp\cred.txt | convertto-securestring
	$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "medline-nt\pa-erudakov",$password
	
	New-PSDrive -Name K -PSProvider FileSystem -Root "\\$comp\c$" -Persist -Credential $cred -Scope Global
	if (Test-Path 'K:\Temp\WinCollectInstall') {
		Remove-Item 'K:\Temp\WinCollectInstall' -Recurse
	}
	Copy-Item -Path "C:\Temp\WinCollectInstall" -Destination "K:\Temp\" -Recurse
	
	Remove-PSDrive -Name "K" -Force
}