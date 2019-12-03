#
#$group = "Domain Admins"
$group = "SD-TS-US_Servers-Admin"
$aline = @()
$members = Get-ADGroupMember -Identity $group -Recursive 
foreach ($member in $members) {
	if(($member.distinguishedName).IndexOf("CN=Managed Service Accounts") -lt 0){
		$user = Get-ADUser $member -Properties mail
		if($user.mail) {
			$managers = Get-ADUser -Filter { emailaddress -Like $user.mail} -Properties manager
			$managerAcc = $null  
			foreach($manager in $managers){
				if(($manager.Manager -ne "") -and ($manager.Manager) ) {
					$managerAcc = Get-ADUser $manager.Manager
				}
				if(($manager.distinguishedName).IndexOf("OU=PA Accounts") -lt 0){
					$amanager = $manager.distinguishedName.Split(",")
					$location = $amanager[$amanager.Count-4].Split('=')[1]
				}
			} 
			$line =[ordered] @{
				"Name" = $user.Name
				"Name DN" =$user.DistinguishedName
				"Enabled" = $user.Enabled
				"SamAccountName" = $user.SamAccountName
				"Email" = $user.mail
				"Location" = $location
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
				"Location" = ""
				"Manager Name" = ""
				"Manager SamAccountName" = ""
				"Manager Name DN" = ""
			}
			
		}
		$aline += New-Object -Property $line -TypeName PSObject
	}
}

$aline | export-csv C:\Temp\serverAdmUsers.csv -NoTypeInformation