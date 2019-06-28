
$groups = Get-Content C:\Temp\Agroups.txt
$outpath = "C:\Temp\Agroups.xlsx"
if (Test-Path $outpath -PathType Leaf ) {
	Remove-Item -path $outpath
}
foreach($group in $groups){
    $aline = @()
	$group
	$members= $null
	try {
		$members = (Get-ADGroup -Identity $group -properties Members).members
	} 
	catch {
		Write-Host "Unable to obtain members for $group"
	}
	foreach ($member in $members) {
		$ADobj = Get-ADObject $member -Properties msds-principalname,distinguishedName,Name,sAMAccountName
		$class = $ADobj.ObjectClass
		switch ($class) {			
			"foreignSecurityPrincipal" {
				#$user = Get-ADObject $member -Properties msds-principalname
				$line =[ordered] @{
					"Class" = "FSP"
					"distinguishedName" = $ADobj.distinguishedName
					"SamAccountName" =""
					"Name" = $ADobj.Name
					"UserPrincipalName" = $ADobj.'msds-principalname'
					"enabled" = ""
					"LockedOut" = ""
					"passwordneverexpires" = ""
				}
				$aline += New-Object -Property $line -TypeName PSObject
			}
			"User" {
				$user = Get-ADUser $member -Properties distinguishedName,SamAccountName,Name,UserPrincipalName,enabled,LockedOut,passwordneverexpires
				$line =[ordered] @{
					"Class" = "User"
					"distinguishedName" = $user.distinguishedName
					"SamAccountName" =$user.SamAccountName
					"Name" = $user.Name
					"UserPrincipalName" = $user.UserPrincipalName
					"enabled" = $user.enabled
					"LockedOut" = $user.LockedOut
					"passwordneverexpires" = $user.passwordneverexpires
				}
				$aline += New-Object -Property $line -TypeName PSObject
			}
			"Group" {
				$line =[ordered] @{
					"Class" = "Group"
					"distinguishedName" = $ADobj.distinguishedName
					"SamAccountName" =$ADobj.sAMAccountName
					"Name" = $ADobj.Name
					"UserPrincipalName" = ""
					"enabled" = ""
					"LockedOut" = ""
					"passwordneverexpires" = ""
				}
				$aline += New-Object -Property $line -TypeName PSObject	
			}	
		}	
	}
	$aline | Export-Excel -Path $outpath -WorksheetName "$group" 
} 