$names = @()
[xml]$NPS3Conf = Get-Content 'C:\Temp\NPS Centurion\NPSconf\npsConf-p01svnps01.xml'
#$nodes = Select-Xml -Xml $NPS3Conf -XPath '//Microsoft_Radius_Protocol/Children/Clients/Children' | Select-Object -ExpandProperty Node
$nodes = $NPS3Conf.Root.Children.Microsoft_Internet_Authentication_Service.Children.Protocols.Children.Microsoft_Radius_Protocol.Children.Clients.Children.ChildNodes
foreach ($node in $nodes){
	
	$line =[ordered] @{
		"Name" = $node.name
		"IP"   = $node.Properties.IP_Address.'#text'
		"Enabled" = $node.Properties.Radius_Client_Enabled.'#text'
		"Secret" = $node.Properties.Shared_Secret.'#text'
	}
	$names += New-Object -Property $line -TypeName PSObject
}

$names | Export-Csv 'C:\Temp\NPS Centurion\NPSconf\npsConf-p01svnps01.csv' -NoTypeInformation