$name  = "Xusers"
$users = Get-Content "C:\Temp\$name.txt"
$nameNO = "C:\Temp\$name" + "NO.txt"
foreach($user in $users){
	
	if( !([bool] (Get-ADUser -Filter { SamAccountName -eq $user })) ){
		Add-Content $nameNo "$($user)"
	}
	
}
