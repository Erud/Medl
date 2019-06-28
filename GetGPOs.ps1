$computers = Get-Content C:\Temp\GroupsToDelete.txt
$GPOs =@()
foreach ($comp in $computers) {
	if ($comp.Length -gt 0) {
		$GPOs += Get-GPO -Name $comp | select *
	}
} 
$GPOs | Export-Csv C:\Temp\GPOs.csv -NoTypeInformation