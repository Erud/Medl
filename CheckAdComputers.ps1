$results = @()
$resultls = @()
ForEach ($server in (get-content "C:\Temp\Servers move to OU\serverlist.txt")) 

{   
	$dc = $server.Split('/')[0]
	#-----------------------------------------------------
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
	$Resultl = $null
	#------------------------------------------------------
	Try {
		$Resultl = Get-ADComputer $oul -ErrorAction Stop -Server $dc -Properties * | 
		Select CN, Created,LastLogonDate,@{name ="pwdLastSet"; expression={[datetime]::FromFileTime($_.pwdLastSet)}},Description,DistinguishedName,Enabled, IPv4Address,OperatingSystem,ManagedBy  
		$Result = $true
		$resultls += $Resultl 
	}
	Catch {
		$Result = $False
	}
	$line =[ordered] @{
		Name = $server
		Found = $Result
	}
	$results += New-Object -Property $line -TypeName PSObject
}
$results | Export-Csv "C:\Temp\Servers move to OU\SerRes.csv" -NoTypeInformation
$resultls | Export-Csv "C:\Temp\Servers move to OU\SerResl.csv" -NoTypeInformation