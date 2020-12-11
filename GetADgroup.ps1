$outpath = "C:\Temp\SecGroups1.csv"
$aline =@()
$groups = Get-Content 'C:\Temp\SecGroups1.txt'
foreach ($group in $groups) {
	$group
	$obj = $null
	try { 
		$obj = Get-ADGroup -Identity $group -Properties CN,Description,DisplayName,DistinguishedName,GroupCategory,GroupScope,info,ManagedBy,MemberOf,Members,Name,ObjectClass,ProtectedFromAccidentalDeletion
	}
	catch {
		Write-Host $_ -ForegroundColor Red
	}
	if($obj) {
		$aline += $obj
	}
}
if (Test-Path $outpath -PathType Leaf ) {
	Remove-Item -path $outpath }
$aline | Export-Csv $outpath -NoTypeInformation