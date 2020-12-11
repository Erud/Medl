#Get-WinEvent -ListProvider *'Group Policy'*
#(Get-WinEvent -ListProvider Microsoft-Windows-GroupPolicy).Events | Format-Table Id, Description

#Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" –MaxEvents 350 |
$EventId = 5311,5312,5313,8005,5310,5309,5308,4005,8004,4004,8002,8003
$Date = (Get-Date).AddHours(-2)
Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-GroupPolicy/Operational';Id=$EventId ;StartTime=$Date} –MaxEvents 50 |
select timecreated,ID,Message,UserId,OpcodeDisplayName | 
Export-Csv c:\temp\GPlogTest1.csv -NoTypeInformation