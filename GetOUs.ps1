$aline =@()
Import-Module ActiveDirectory
$ous = Get-ADObject -Filter 'ObjectClass -eq "organizationalUnit"' 

foreach($ou in $ous){
	$oudn = $ou.DistinguishedName.Split(',')
	[array]::Reverse($oudn)
	$line = ''
	foreach($oud in $oudn){
		if ($line -ne ''){
			$line = $line + ';'+ $oud.split('=')[1]
		}
		else{
			$line = $oud.split('=')[1] 
		}
	}
	$str =[ordered] @{
		"DistinguishedName" =$ou.DistinguishedName
		"Name" = $ou.Name
		"Count" = (Get-ADObject -Filter {ObjectClass -ne 'organizationalUnit'} -SearchBase $ou.DistinguishedName -SearchScope Subtree).Count
		"Str" = $line
	}
	$aline += New-Object -Property $str -TypeName PSObject
}

$aline | Export-Csv C:\Temp\allou.csv -NoTypeInformation