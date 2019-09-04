$ComputerName = "MUNPRDSCJNK1"
$DomainName = "medline.com"
$GroupName = "SD-TS-MUNPRDSCJNK1-Admin"
$ComputerName
		$AdminGroup = [ADSI]"WinNT://$ComputerName/Administrators,group"
		$Group = [ADSI]"WinNT://$DomainName/$GroupName,Group"

$AdminGroup.Add($Group.Path)