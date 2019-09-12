#$WebResponse = Invoke-WebRequest "http://www.openculture.com/free_certificate_courses"
$WebResponse = Invoke-WebRequest "http://www.openculture.com/freeonlinecourses"
<#$WebResponse

$WebResponse.GetType()
$WebResponse| Get-Member
$WebResponse.AllElements#>

$WebResponse.AllElements | Where {$_.TagName -eq "LI"} | Select innerText | Export-Csv C:\Temp\cListfree.csv -NoTypeInformation