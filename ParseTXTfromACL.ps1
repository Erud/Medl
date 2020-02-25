$lines = get-content C:\temp\allOUres.txt
$outline = ""
foreach ($line in $lines) {
	if($line.Length -gt 3) {
		$switch = $line.Substring(0,3)
		Switch ($switch)
		{
			"CN=" { $outline = $line;break }
			
			"All" { if($line.Substring(17,5) -eq "Domai"){ 
					$outline += ";"+$line.Substring(6)};break }
			"Own" { $outline += ";"+$line.Substring(7);break }
			"---" { $outline;$outline = "";break }
			default {break}
		}
	}
}

#		"All" { if($line.Substring(17,5) -eq "SD-Ad"){ 
#				$outline += ";"+$line.Substring(6)};break }