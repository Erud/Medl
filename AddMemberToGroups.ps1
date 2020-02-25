#$name = "2008s"
# SD-TS-C47VIDEO2-Admin
Import-Module ActiveDirectory
$Cred = Get-Credential 'medline-nt\pa-erudakov'
$computers = get-content C:\temp\Marzarella_serverOK.txt
foreach ($comp in $computers) {
	$comp = $comp.Trim()
	#$comp
    $group = "SD-TS-" + $comp + "-Admin"
    $group
    Add-ADGroupMember -Identity $group -Members "pa-vmarzarella" -Credential $Cred
}