#Get-GPOReport -All -ReportType HTML -Path c:\temp\GPO.html

$GPOname = "SPT Setup Room PC Lockdown"

Get-GPOReport -Name $GPOname -ReportType HTML -Path "C:\temp\GPOReports\$gponame.html"