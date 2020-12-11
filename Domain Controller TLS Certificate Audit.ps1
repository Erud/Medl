<#-----------------------------------------------------------------------------

Name: Domain Controller TLS Certificate Audit
Description: Retrieves the certificate status of all domain controllers currently
allowing TLS connections. Also performs basic certifcate validation as well.

#>

# Some Prep Work
Import-Module ActiveDirectory
$ServerPort = "636"	# Optionally you could use 3269 for GC-S
$ForestDCs = @()	# Our list of all Forest domain controllers
$DC_Certs = @()		# Our list of DC's and their certificate status

$ErrorActionPreference = 'SilentlyContinue'
# Lets retrieve every domain controller in the forest

$ForestDCs = Get-ADComputer -LDAPFilter "(&(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=8192))"

# Loop through all of our DC's and retrieve their certificate status.
ForEach($Server in $ForestDCs){
	
	$ServerName = $Server.DNSHostName
	#if (($ServerName -ne 'MEXPRDDC01.medline.com') -and ($ServerName -ne 'MUNTSTSPDC1.medline.com')){
    if ($ServerName.StartsWith('MUNPRDD')){
		$Row = '' | select Server, Status, Subject, SAN, Issuer, ValidFrom, ValidTo, ThumbPrint, V1TemplateName,V2TemplateName,SKI,AKI,BKU,EKU,AppPolicies
		$Row.Server = $ServerName
		
		# Try to make the Connection
		Try 
		{	
			$Connection = New-Object System.Net.Sockets.TcpClient($ServerName,$ServerPort)	
			$TLSStream = New-Object System.Net.Security.SslStream($Connection.GetStream()) -ErrorAction SilentlyContinue
			
			#Try to validate the certificate, break out if we don't
			Try {
				#$TLSStatus = $TLSStream.AuthenticateAsClient($ServerName) 
                $TLSStatus = $TLSStream.AuthenticateAsClient($ServerName,$null,"Tls12",$false)
			} 
			Catch {$Row.Status = "Failed Validation" ; $DC_Certs+= $Row ; $Connection.Close ; Break}
			
			$Row.Status = "OK"
			
			#Grab the Cert and it's Basic Properties
			$RemoteCert = New-Object system.security.cryptography.x509certificates.x509certificate2($TLSStream.get_remotecertificate())
			$Row.Subject = $RemoteCert.Subject
			$Row.Issuer = $RemoteCert.Issuer
			$Row.ValidFrom = $RemoteCert.NotBefore
			$Row.ValidTo = $RemoteCert.NotAfter
			$Row.Thumbprint = $RemoteCert.Thumbprint
			
			#Grab the more Advanced properties.
			Try {$Row.SAN = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '2.5.29.17'}).Format(0)} Catch{}
			Try {$Row.V1TemplateName = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '1.3.6.1.4.1.311.20.2'}).Format(0)} Catch{}
			Try {$Row.V2TemplateName = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '1.3.6.1.4.1.311.21.7'}).Format(0)} Catch{}
			Try {$Row.SKI = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '2.5.29.14'}).Format(0)} Catch{}
			Try {$Row.AKI = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '2.5.29.35'}).Format(0)} Catch{}
			Try {$Row.BKU = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '2.5.29.15'}).Format(0)} Catch{}
			Try {$Row.EKU = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '2.5.29.37'}).Format(0)} Catch{}
			Try {$Row.AppPolicies = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '1.3.6.1.4.1.311.21.10'}).Format(0)} Catch{}
			Try {$Row.CDP = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '2.5.29.31'}).Format(0)} Catch{}
			Try {$Row.AIA = ($RemoteCert.Extensions | Where-Object {$_.Oid.Value -eq '1.3.6.1.5.5.7.1.1'}).Format(0)} Catch{}
			$DC_Certs+= $Row
		}
		Catch {$Row.Status = 'No Connection Available' ; $DC_Certs+= $Row }
		Finally {$Connection.Close()}
	}	
}
#Export it Out and also Display
$DC_Certs | out-gridview -Title "Domain Controller TLS Certificate Audit"
$DC_Certs | export-csv -notypeinformation -path C:\temp\DC-TLS-Cert-Audit.csv
Write-Host $DC_Certs.Count "records saved to C:\temp\DC-TLS-Cert-Audit.csv"