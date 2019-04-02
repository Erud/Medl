$aline =@()
$groups = Get-LocalGroup
foreach ($group in $groups) {
	$members = Get-LocalGroupMember -Name $group
	foreach($member in $members) {
		if ($member.ObjectClass -eq "User"){
			if ( ($member.Name).Split("\")[0] -eq $env:COMPUTERNAME) {
				$memberST = (Get-LocalUser -Name ($member.Name).Split("\")[1]).Enabled
			}
			else {
				$memberST = (Get-ADUser -Identity ($member.Name).Split("\")[1]).Enabled
			}
		}	
		else {$memberST = ""}
		
		$line =[ordered] @{
			"Group Name" =$group.Name
			"Group Description" = $group.Description
			"Member Name" = $member.Name
			"Member Class" = $member.ObjectClass
			"Member Enabled" = $memberST
		}
		$aline += New-Object -Property $line -TypeName PSObject
	}
}
$aline | Out-GridView