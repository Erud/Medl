$DomainName = "medline.com"
#$ComputerName = "MUNDEVSPOWA01" #Computer name
$GroupName = "RD-ECOM-DEV-Users"
$Computers = Get-Content C:\Temp\compEcDEV.txt
foreach ($ComputerName in $Computers) {
	if(Test-Connection -Cn $ComputerName -BufferSize 16 -Count 1 -ErrorAction 0 -quiet){
		$ComputerName
		$AdminGroup = [ADSI]"WinNT://$ComputerName/Administrators,group"
		$Group = [ADSI]"WinNT://$DomainName/$GroupName,Group"
		Try {
			$AdminGroup.Add($Group.Path)
		} 
		Catch {
			"$($ComputerName): Add Group error"
		}
	} 
	else {
		"$($ComputerName): Offline"
	}
}