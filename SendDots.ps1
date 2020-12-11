param($minutes = 160)

$myshell = New-Object -com "Wscript.Shell"

for ($i = 0; $i -lt $minutes; $i++) {	
	Start-Sleep -Seconds 60
	$myshell.sendkeys("$i")
	if ($i%2) {
		$myshell.sendkeys("<")
	} else {
		$myshell.sendkeys(">")
	}
}