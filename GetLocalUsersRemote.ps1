$computers = "MUNDEVENDECA"
$PScreds = Get-Credential "MEDLINE-NT\PA-ERUDAKOV"
Invoke-Command -ScriptBlock {
	[ADSI]$S = "WinNT://$($env:computername)"
	$S.children.where({$_.class -eq 'group'}) |
	Select @{Name="Name";Expression={$_.name.value}},
	@{Name="Members";Expression={
			[ADSI]$group = "$($_.Parent)/$($_.Name),group"
			$members = $Group.psbase.Invoke("Members")
			($members | ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}) -join ";"}
	}
} -ComputerName $computers -Credential $PScreds| 
Select PSComputername,Name,Members |
Export-CSV -path c:\temp\localaudit.csv –notypeinformation