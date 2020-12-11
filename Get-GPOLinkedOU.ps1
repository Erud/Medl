
$gpos = Get-Gpo -All
$count = $gpos.count
$i=0
$array = @()
foreach ($gpo in $gpos) {
	$i++
	Write-Progress -Activity 'GPO Scan' -Status ("GPO: {0}" -f $gpo.DisplayName) -PercentComplete (($i/$count)*100)
	[xml]$gpoReport = Get-GPOReport -Guid $gpo.ID -ReportType xml
	if ($gpoReport.GPO.LinksTo.Count -gt 0) {
		$links = $gpoReport.GPO.LinksTo
		foreach ($link in $links){
			$line = New-Object PSObject -Property @{
				GPOName = $gpo.DisplayName
				SOMName = $link.SOMName
				SOMPath = $link.SOMPath
				Enabled = $link.Enabled
				NoOverride = $link.NoOverride }
			$array += $line
		}
	}
}
$array | Export-Csv 'c:\temp\GPOlinksOU.csv' -NoTypeInformation