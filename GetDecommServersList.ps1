#EER 10/15/2019 
[String]$WebDAVShare = '\\collaboration.medline.com@SSL\DavWWWRoot\sites\is\server\Decom tracking'
New-PSDrive -Name Z -PSProvider FileSystem -Root $WebDAVShare

$servers = Get-ChildItem -Path Z:
$names = @()
foreach($server in $servers){
	$name = ($server.Name).ToLower()
	$l = $name.IndexOf("decom")
	if($l -le 1){
		$first = ($server.name).Substring(0,$name.Length - 5)
	}
	else{
		$first = ($server.name).Substring(0,$l - 1)
	}
	
	$line =[ordered] @{
		"Name" = $first
		"NameF" = $server.Name
		"LastWriteTime" = $server.LastWriteTime
	}
	$names += New-Object -Property $line -TypeName PSObject
}

$names | Export-Csv C:\Temp\decom.csv -NoTypeInformation

Remove-PSDrive -Name Z