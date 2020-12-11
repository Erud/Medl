#.\Get-GPOLogonScriptReport.ps1 | Export-Csv 'c:\temp\GPOLogonScripts.csv' -NoTypeInformation

Import-Module GroupPolicy -ErrorAction Stop
$gpos = @(Get-GPO -All)
$count = $gpos.count
$i=0
ForEach ($gpo in $gpos) {
	#Start-Sleep -Seconds 5
	$i++
	Write-Progress -Activity 'GPO Scan' -Status ("GPO: {0}" -f $gpo.DisplayName) -PercentComplete (($i/$count)*100)
	$xml = [xml]($gpo | Get-GPOReport -ReportType XML)
	#User logon script
	$userScripts = @($xml.GPO.User.ExtensionData | Where {$_.Name -eq 'Scripts'})
	If ($userScripts.count -gt 0) {
		$userScripts.extension.Script | ForEach {
			New-Object PSObject -Property @{
				GPOName = $gpo.DisplayName
				ID = $gpo.ID
				GPOState = $gpo.GpoStatus
				GPOType = 'User'
				Type = $_.Type
				Script = $_.command
                Parameters = $_.Parameters
				ScriptType = $_.command -replace '.*\.(.*)','$1'
			}
		}
	}
	#Computer logon script
	$computerScripts = @($xml.GPO.Computer.ExtensionData | Where {$_.Name -eq 'Scripts'})
	If ($computerScripts.count -gt 0) {
		$computerScripts.extension.Script | ForEach {
			New-Object PSObject -Property @{
				GPOName = $gpo.DisplayName
				ID = $gpo.ID
				GPOState = $gpo.GpoStatus
				GPOType = 'Computer'
				Type = $_.Type
				Script = $_.command
                Parameters = $_.Parameters
				ScriptType = $_.command -replace '.*\.(.*)','$1'
			}
		}
	}
}