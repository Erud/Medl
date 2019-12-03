$name = "2008s"
# SD-TS-C47VIDEO2-Admin
Import-Module ActiveDirectory
$Cred = Get-Credential 'medline-nt\pa-erudakov'
$computers = get-content C:\temp\VideoS.txt
foreach ($comp in $computers) {
	$comp = $comp.Trim()
	$comp
    $group = "SD-TS-" + $comp + "-Admin"
    Add-ADGroupMember -Identity $group -Members "PA-SBarber" -Credential $Cred
}