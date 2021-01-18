$server = "medline.com/Computers/MUNPRDETLJOB04" 
$asrv = $server.Split('/')
$asrvd = $asrv[0].Split('.')
$compl = ',DC='+$asrvd[0]+',DC='+$asrvd[1]
$n = $asrv.Count - 1
$scn = $asrv[$asrv.Count-1]
$oul = ''
for($i=1; $i -lt $n; $i++){

	if($asrv[$i] -eq "Computers") {
		$ou = ',CN='+$asrv[$i]
	} else {
		$ou = ',OU='+$asrv[$i]
	}
	$oul += $ou
}
$oul = 'CN='+$scn+$oul+$compl
Get-ADComputer $oul