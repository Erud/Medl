$group = "Domain Admins"
$aline = @()
$members = Get-ADGroupMember -Identity $group -Recursive 
foreach ($member in $members) {
	$user = Get-ADUser $member -Properties mail
	if($user.mail) {
		$managers = Get-ADUser -Filter { emailaddress -Like $user.mail} -Properties manager
		$managerAcc = $null  
		foreach($manager in $managers){
			if(($manager.Manager -ne "") -and ($manager.Manager) ) {
				$managerAcc = Get-ADUser $manager.Manager
			}
		} 
		$line =[ordered] @{
			"Name" = $user.Name
			"Name DN" =$user.DistinguishedName
			"Enabled" = $user.Enabled
			"SamAccountName" = $user.SamAccountName
			"Email" = $user.mail
			"Manager Name" = $managerAcc.Name
			"Manager SamAccountName" = $managerAcc.SamAccountName
			"Manager Name DN" = $managerAcc.DistinguishedName
		}
	}
	else {
		$line =[ordered] @{
			"Name" = $member.Name
			"Name DN" =$member.DistinguishedName
			"Enabled" = $user.Enabled
			"SamAccountName" = $member.SamAccountName
			"Email" = ""
			"Manager Name" = ""
			"Manager SamAccountName" = ""
			"Manager Name DN" = ""
		}
		
	}
	$aline += New-Object -Property $line -TypeName PSObject
}

$aline | export-csv C:\Temp\domainAdmUsers.csv -NoTypeInformation