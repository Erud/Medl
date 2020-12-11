$name = "W31"
$computers = get-content "c:\temp\$name.txt"

$password = get-content C:\temp\cred.txt | convertto-securestring
$Cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "medline-nt\pa-erudakov",$password

foreach ($comp in $computers) {
	$comp
	if (Test-Path k:) {
		Remove-PSDrive -Name "K" -Force
	}
	try {
		New-PSDrive -Name K -PSProvider FileSystem -Root "\\$comp\c$" -Persist -Credential $cred -Scope Global -ErrorAction Stop
		if (Test-Path 'K:\Temp\specops') {
			Remove-Item 'K:\Temp\specops' -Recurse
		}
		if (-Not (Test-Path 'K:\Temp')) {
			New-Item -Path "K:\" -Name "Temp" -ItemType "directory"
		}
		Copy-Item -Path "C:\Temp\specops" -Destination "K:\Temp\specops" -Recurse
		
		Remove-PSDrive -Name "K" -Force
	}
	catch { "ERROR >>> $comp " }
}