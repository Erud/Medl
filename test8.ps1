$list =@() 
$server=$env:computername
$server | % {
	$server = $_
	$server
	$computer = [ADSI]"WinNT://$server,computer"
	
	$computer.psbase.children | where { $_.psbase.schemaClassName -eq 'group' } | foreach {
		
		$group =[ADSI]$_.psbase.Path
		"`tGroup: " + $Group.Name
		$group.psbase.Invoke("Members") | foreach {
			$us = $_.GetType().InvokeMember("Adspath", 'GetProperty', $null, $_, $null)
			$us = $us -replace "WinNT://",""
			$class = $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
			$list += new-object psobject -property @{Group = $group.Name;Member=$us;MemberClass=$class;Server=$server}
			"`t`tMember: $us ($Class)"
		}
	}
}	