$log = get-content "C:\Temp\NPS Centurion\logs\dc03N.csv"

$i = 0
$parsed =@()
$Row = '' | select Date, Event, Message, User, NAS_IP4, NAS_Id, Client, Server
foreach($line in $log){
	
	if ($line.Length -gt 14) {
		#$line.Substring(1,14) + " " + $i
		$i += 1
		#if ($i -gt 16){break}
		if($line.Substring(0,11) -eq "Information") {
			if ($I -gt 20){ 
				#$Row
				$parsed += $Row
				$Row = '' | select Date, Event, Message, User, NAS_IP4, NAS_Id, Client, Server
				#break
			}
			$lines = $line.Split(',')
			$Row.Date = $Lines[1]
			$Row.Event = $lines[3]
			$Row.Message = $lines[05].Substring(1)
		}
		if($line.Substring(1,13) -eq "Account Name:") {
			$lines = $line.Split("`t")
			if($lines[4] -ne '-'){
				$Row.User = $lines[4]
			}
		}
		if($line.Substring(1,13) -eq "NAS IPv4 Addr") {
			$lines = $line.Split("`t")
			$Row.NAS_IP4 = $lines[3]
		}
		if($line.Substring(1,13) -eq "NAS Identifie") {
			$lines = $line.Split("`t")
			$Row.NAS_Id = $lines[4]
		}
		if($line.Substring(1,13) -eq "Client Friend") {
			$lines = $line.Split("`t")
			$Row.Client = $lines[3]
		}
		if ($line.Length -gt 23) {
			if($line.Substring(1,22) -eq "Authentication Server:") {
				$lines = $line.Split("`t")
				$Row.Server = $lines[3]
			}
		}
	} 
}
$parsed | Export-Csv "C:\Temp\NPS Centurion\logs\dc03NParsed.csv" -NoTypeInformation