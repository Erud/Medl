#68/80-1025025
$aline =@()
$aem = Get-Content C:\Temp\emails.txt
foreach ($em in $aem) {
	$obj = Get-ADObject -Filter {cn -eq $em} -Properties *
	$aline += $obj
}
$aline | Export-Csv C:\Temp\aaem.csv -NoTypeInformation