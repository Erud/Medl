Import-Module ActiveDirectory

$Table = @()

$Groups = Get-AdGroup -filter * -Properties * -SearchBase "OU=*Groups,OU=Medline Industries,DC=medline,DC=com" 

Foreach ($Group in $Groups) {
	
	$Record = [ordered] @{
		"Name"              = $Group.Name
		"Description"       = $Group.Description
		"CanonicalName"     = $Group.CanonicalName
		"DistinguishedName" = $Group.DistinguishedName
		"DisplayName"       = $Group.DisplayName
		"ManagedBy"         = $Group.ManagedBy
		"GroupCategory"     = $Group.GroupCategory
		"GroupScope"        = $Group.GroupScope
		"MembersCount"      = $Group.Members.Count
		"Mail"              = (get-ADGroup $Group -properties mail).mail
		"ProtectedFromAccidentalDeletion" = $Group.ProtectedFromAccidentalDeletion
	}
	
	$objRecord = New-Object PSObject -property $Record
	$Table += $objrecord
}

$Table | export-csv "C:\temp\GroupsInOU.csv" -NoTypeInformation

(get-ADGroup $Group -properties mail).mail