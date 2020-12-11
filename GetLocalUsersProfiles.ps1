$computername = "MUNPRDETLJOB04"
$litem = ''
$items = Get-WmiObject -ClassName Win32_UserProfile -ComputerName $computername | select SID,LocalPath
Foreach ($item in $items) {
	$objUser = New-Object System.Security.Principal.SecurityIdentifier($item.SID) 
	try {
		$objName = $objUser.Translate([System.Security.Principal.NTAccount]) 
		$item.SID = $objName.value
	}
	catch {} #$item.SID }
	if($item.SID.Substring(0,5) -ne 'S-1-5'){
		$aitem = $item.SID.Split('\')
		if($aitem[0] -eq 'MEDLINE-NT'){
			if($aitem[1].Substring(0,3) -eq 'pa-'){
				$litem += $aitem[1].Substring(3) +';'
			}
			else {
				if($aitem[1].Substring(0,3) -ne 'svc'){
					$litem += $aitem[1] +';'
				}
			}
		}
	}
}

$litem

$litem  | Set-Clipboard
