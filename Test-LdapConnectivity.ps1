#********************************************************************** 
# Test-LDAPConnectivity.ps1 
# This script is designed to Test the connectivity to LDAP, wether it is Open LDAP or Active Directory 
# Author: Mike Burr 
# Modified On: 29-SEP-2016 
# Modifed By: Harmik Singh Batth 
# Version: 1.0 
# Change History: 
# 
# 
#********************************************************************** 
 
Function Test-LdapConnectivity 
{ 
param( 
[String]$ServerName = "", 
[UInt16]$Port = 389, 
[String]$UserName = "", 
[String]$Password = "" 
) 
#Main script 
Clear-host 
 
#Check if all arguments are passedd 
if (!$serverName -or !$Port -or !$UserName -or !$Password) 
{ 
Write-Host "USAGE: Test-LDAPConnectivity.ps1 ServerName Port UserName Password" 
write-host "Paramaters not defined properly, script will exit now" 
break 
} 
 
if (!$serverName) {write-host "Please define Server Name"} 
if (!$Port) {write-host "Please define Port"} 
if (!$UserName) {write-host "Please define Username"} 
if (!$Password) {write-host "Please define Password"} 
 
#Load the assemblies 
[System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols") 
[System.Reflection.Assembly]::LoadWithPartialName("System.Net") 
 
#Connects to Server on the standard port 
$dn = "$ServerName"+":"+"$Port" 
$c = New-Object System.DirectoryServices.Protocols.LdapConnection "$dn" 
$c.SessionOptions.SecureSocketLayer = $false; 
$c.SessionOptions.ProtocolVersion = 3 
 
# Pick Authentication type: 
# Anonymous, Basic, Digest, DPA (Distributed Password Authentication), 
# External, Kerberos, Msn, Negotiate, Ntlm, Sicily 
$c.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic 
 
$credentials = new-object "System.Net.NetworkCredential" -ArgumentList $UserName,$Password 
 
# Bind with the network credentials. Depending on the type of server, 
# the username will take different forms. Authentication type is controlled 
# above with the AuthType 
Try 
{ 
 
$c.Bind($credentials); 
Write-Verbose "Successfully bound to LDAP!" -Verbose 
return $true 
} 
catch 
{ 
Write-host $_.Exception.Message 
 
return $false 
} 
 
} 
 
#------------------------------------------------------------------------- 
 
#USAGE: 
 
#e.g. 
#Test-LDAPConnectivity.ps1 (Read-host "Enter Server Name") (Read-host "Enter LDAP Port") (Read-host "Enter LDAP Admin username") (Read-host "Enter Password" -AsSecureString)

#Test-LDAPConnectivity (Read-host "Enter Server Name") (Read-host "Enter LDAP Port") (Read-host "Enter LDAP Admin username") (Read-host "Enter Password" -AsSecureString)
Test-LdapConnectivity "munprddc03" "389" "CN=Rudakov\, Ed,OU=Users,OU=Contractors_Consultants,OU=Users_And_Computers,DC=medline,DC=com" (Read-host "Enter Password" -AsSecureString)