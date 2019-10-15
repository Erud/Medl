$computers = get-content c:\temp\DejaBlueServers.txt
foreach ($comp in $computers) {
	$comp
	if(Test-Connection -Cn $comp -BufferSize 16 -Count 1 -ErrorAction 0 -quiet){
		# ok
		Add-Content C:\Temp\DejaBlueServersK.txt "$($comp)"
	}
	else {
		#	$comp += " No Ping" 
		#	$comp
		Add-Content C:\Temp\DejaBlueServersN.txt "$($comp)"
	}
}