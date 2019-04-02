$aline =@()
$comp = $env:computername
[ADSI]$S = "WinNT://$($comp)"
$groups = $S.children.where({$_.class -eq 'group'}) 
foreach ($groupO in $groups) {
	[ADSI]$group = "$($groupO.Parent)/$($groupO.Name),group"
	$members = $Group.psbase.Invoke("Members")
	$emt = $true
	$members | ForEach-Object {
		$path = ($_.GetType().InvokeMember("Adspath", 'GetProperty', $null, $_, $null)) -replace "WinNT://",""
		$apath = $path -split ("/",3)
		if ($apath[1] -eq $comp) {$path = $apath[1] + "/" + $apath[2] } 
		$line =[ordered] @{
			"Computer" = $comp
			"Group Name" =$group.name.value
			"Group Description" = $group.Description.value
			"Member Name" = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
			"Member Class" = $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
			"Member Path" = $path
		}
		$aline += New-Object -Property $line -TypeName PSObject
		$emt = $false
	}
	if ($emt){
		$line =[ordered] @{
			"Computer" = $comp
			"Group Name" =$group.name.value
			"Group Description" = $group.Description.value
			"Member Name" = ""
			"Member Class" = ""
			"Member Path" = ""
		}
		$aline += New-Object -Property $line -TypeName PSObject
	}
}
$aline | select "Computer","Group Name","Group Description","Member Name","Member Class","Member Path" |Out-GridView