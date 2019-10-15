#https://<consoleFQDN:port>/st/console/api/v1.0/machinegroups/?count=10 3121 
$WebResponse = Invoke-WebRequest "https://munprdipm01.medline.com:3121/st/console/api/v1.0/machinegroups"
$WebResponse