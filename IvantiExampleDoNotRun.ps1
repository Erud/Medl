cls
#################################################################################
#
#                               DISCLAIMER: EXAMPLE ONLY
#
# Execute this example at your own risk. The console, target machines and  
# databases should be backed up prior to executing this example. Ivanti does 
# not warrant that the functions contained in this example will be
# uninterrupted or free of error. The entire risk as to the results and
# performance of this example is assumed by the person executing the example.
# Ivanti is not responsible for any damage caused by this example.
#
#################################################################################
# Reboot the machine to scan immediately after deployment
$reboot = $false
 
# Deploy ALL missing patches
$deployPatches = $false
 
# Delete the sample data from the application
$deleteSampleData = $true
 
# IP Address, NETBios Name or FQDN
$machineToScan =  "127.0.0.1"
 
# What CVE do you want to add to the patch group and deploy to the machine to scan?
#
# The null patches is always scanned for. This will be in addition to
#
# Example @("CVE1", "CVE2")
$cveList = @()
 
$loggedOnUserName = "$env:USERDOMAIN\$env:USERNAME"
 
# The Console's IP Address, NETBios Name or FQDN
$apiServer = "$env:computername.$env:userdnsdomain" #"$env:USERDOMAIN"
$apiLocalPort = 3121
 
$Uris =
@{
	AssetScanTemplates = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/asset/scantemplates"
	Credentials = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/credentials"
	CertificateConsole = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/configuration/certificate"	
	DistributionServers = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/distributionservers"
	Hypervisors = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/virtual/hypervisors"
	IPRanges = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/ipranges"
	MachineGroups = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/machinegroups"
	MetadataVendors = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/metadata/vendors"
	NullPatch = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patches?bulletinIds=MSST-001"
	Operations = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/operations"
	Patches = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patches"
	PatchDeployments = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/deployments"
	PatchDeployTemplates = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/deploytemplates"
	PatchDownloads = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/downloads"
	PatchDownloadsScansPatch = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/downloads/scans"
	PatchGroups = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/groups"
	PatchMetaData = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/patchmetadata"
	PatchScans = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/scans"
	PatchScanMachines = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/scans/{0}/machines"
	PatchScanMachinesPatches = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/scans/{0}/machines/{1}/patches"
	PatchScanTemplates = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/patch/scanTemplates"
	VCenters = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/virtual/vcenters"
	VirtualInfrastructure = "https://$apiServer`:$apiLocalPort/st/console/api/v1.0/virtual"
}
Add-Type -AssemblyName System.Security
#Encrypt using RSA
function Encrypt-RSAConsoleCert
{
	param
	(
		[Parameter(Mandatory=$True, Position = 0)]
		[Byte[]]$ToEncrypt
	)
	try
	{
		$certResponse = Invoke-RestMethod $Uris.CertificateConsole -Method Get -UseDefaultCredentials -Verbose
		[Byte[]] $rawBytes = ([Convert]::FromBase64String($certResponse.derEncoded))
		$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(,$rawBytes)
		$rsaPublicKey = $cert.PublicKey.Key;
 
		$encryptedKey = $rsaPublicKey.Encrypt($ToEncrypt, $True);
		return $encryptedKey
	}
	finally
	{
		$cert.Dispose();
	}
}
 
function Create-CredentialRequest
{
	param
	(
		[Parameter(Mandatory=$True, Position=0)]
		[String]$FriendlyName,
 
		[Parameter(Mandatory=$True, Position=1)]
		[String]$UserName,
 
		[Parameter(Mandatory=$True, Position=2)]
		[ValidateNotNull()]
		[SecureString]$Password
	)
 
	$body = @{ "userName" = $UserName; "name" = $FriendlyName; }
	$bstr = [IntPtr]::Zero;
	try
	{
		## Create an AES 128 Session key.
		$algorithm = [System.Security.Cryptography.Xml.EncryptedXml]::XmlEncAES128Url
		$aes = [System.Security.Cryptography.SymmetricAlgorithm]::Create($algorithm);
		$keyBytes = $aes.Key;
 
		# Encrypt the session key with the console cert
		$encryptedKey = Encrypt-RSAConsoleCert -ToEncrypt $keyBytes
		$session = @{ "algorithmIdentifier" = $algorithm; "encryptedKey" = [Convert]::ToBase64String($encryptedKey); "iv" = [Convert]::ToBase64String($aes.IV); }
 
		# Encrypt the password with the Session key.
		$cryptoTransform = $aes.CreateEncryptor();
 
		# Copy the BSTR contents to a byte array, excluding the trailing string terminator.
		$size = [System.Text.Encoding]::Unicode.GetMaxByteCount($Password.Length - 1);
 
		$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
		$clearTextPasswordArray = New-Object Byte[] $size
		[System.Runtime.InteropServices.Marshal]::Copy($bstr, $clearTextPasswordArray, 0, $size)
		$cipherText = $cryptoTransform.TransformFinalBlock($clearTextPasswordArray, 0 , $size)
 
		$passwordJson = @{ "cipherText" = $cipherText; "protectionMode" = "SessionKey"; "sessionKey" = $session }
	}
	finally
	{
		# Ensure All sensitive byte arrays are cleared and all crypto keys/handles are disposed.
		if ($clearTextPasswordArray -ne $null)
		{
			[Array]::Clear($clearTextPasswordArray, 0, $size)
		}
		if ($keyBytes -ne $null)
		{
			[Array]::Clear($keyBytes, 0, $keyBytes.Length);
		}
		if ($bstr -ne [IntPtr]::Zero)
		{
			[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
		}
		if ($cryptoTransform -ne $null)
		{
			$cryptoTransform.Dispose();
		}
		if ($aes -ne $null)
		{
			$aes.Dispose();
		}
	}
	$body.Add("password", $passwordJson)
	return ConvertTo-JSon $Body -Depth 99
}
function Get-PaginatedResults
{
	param
	(
		[String]$uri,
		[PSCredential]$runAsCredential
	)
 
	$entireList = [System.Collections.ArrayList]@()
	$nextUri = $uri
	do
	{
		$result = Invoke-RestMethod $nextUri -Method Get -ErrorAction Stop -Credential $runAsCredential -Verbose
		$result.value | Foreach-Object { $entireList.Add($_) }
 
		$nextUri = $result.links.next.href
	} until ($nextUri -eq $null)
 
	return $entireList
}
 
function Remove-RestResourceSafe
{
	param
	(
		[String]$Uri,
		[PSCredential] $runAsCredential
	)
	try
	{
		Invoke-RestMethod $uri -Method Delete -Credential $runAsCredential -Verbose > $null
	}
	catch
	{
	}
}
 
function Wait-Operation {
	param(
		[String] $OperationLocation,
		[Int32] $TimeoutMinutes,
		[PSCredential]$runAsCredential
	)
 
	$startTime = [DateTime]::Now
	$operationResult = Invoke-RestMethod -Uri $OperationLocation -Method Get -Credential $runAsCredential -Verbose
	while ($operationResult.Status -eq 'Running')
	{
		if ([DateTime]::Now -gt $startTime.AddMinutes($TimeoutMinutes))
		{
			throw "Timed out waiting for operation to complete"
		}
 
		Start-Sleep 5
		$operationResult = Invoke-RestMethod -Uri $OperationLocation -Method Get -Credential $runAsCredential -Verbose
	}
 
	return $operationResult
}
function Add-Credential
{
	Param
	(
		[String]$credentialName,
		[PSCredential]$credential,
		[PSCredential]$runAsCredential
	)
#	$body = @{ name = $credentialName; password = @{cipherText = $cipherText; protectionMode = "SessionKey"; sessionKey = "AES" }; username = $credential.UserName } | ConvertTo-Json -Depth 99
#	$response = Invoke-RestMethod -Uri $Uris.Credentials -Method Post -Body $body -ContentType "application/json" -Credential $runAsCredential -Verbose
 
	$body = Create-CredentialRequest -FriendlyName $credentialName -UserName $credential.UserName -Password $credential.Password
	$response = Invoke-RestMethod -Uri $Uris.Credentials -Method Post -Body $body -ContentType "application/json" -UseDefaultCredentials -Verbose
	return $response
}
 
function Add-MachineGroup
{
	Param
	(
		[String]$groupName,
		[String]$machineName,
		[String]$loginCredentialid,
		[PSCredential]$runAsCredential
	)
		$body =
			@{
				name = $groupName;
				discoveryFilters =  @(
				@{
					AdminCredentialId = $loginCredentialid;
					category = "MachineName";
					name = $machineName
				})
			} |  ConvertTo-Json -Depth 99
	$response = Invoke-RestMethod -Uri $Uris.MachineGroups -Method Post -Body $body -ContentType "application/json" -Credential $runAsCredential
	return $response
}
 
function Add-CveToPatchGroup
{
	Param
	(
		[String]$id,
		[String]$cve,
		[PSCredential]$runAsCredential
	)
 
	$body = @{ Cve = $cve; } | ConvertTo-Json -Depth 99
	Invoke-RestMethod -Uri "$($Uris.PatchGroups)/$($id)/patches/cve" -Method Post -Body $body -ContentType "application/json" -Credential $runAsCredential > $null
}
 
function Add-NullPatchToPatchGroup
{
	Param
	(
		[String]$id,
		[PSCredential]$runAsCredential
	)
 
	$nullPatchResult = Invoke-RestMethod -Uri $Uris.NullPatch -Method Get -Credential $runAsCredential -Verbose
	foreach($value in $nullPatchResult.value)
	{
		foreach ($vulnerability in $value.vulnerabilities)
		{
			$body = ConvertTo-Json -Depth 99 -InputObject  @(, $vulnerability.id)
			Invoke-RestMethod -Uri "$($Uris.PatchGroups)/$($id)/patches" -Method POST -Body $body -ContentType "application/json" -Credential $runAsCredential > $null
		}
	}
}
 
function Add-PatchGroup
{
	Param
	(
		[String]$groupName,
		[PSCredential]$runAsCredential
	)
	$body = @{ name = $groupName; } | ConvertTo-Json -Depth 99
	$response = Invoke-RestMethod -Uri $Uris.PatchGroups -Method Post -Body $body -ContentType "application/json" -Credential $runAsCredential
	return $response
}
 
function Add-PatchScanTemplate
{
	Param
	(
		[String]$templateName,
		[String]$patchGroupId,
		[PSCredential]$runAsCredential
	)
	$body = @{ name = $templateName; PatchFilter = @{ patchGroupFilterType = 'Scan'; patchGroupIds = @($patchGroupId) }} | ConvertTo-Json -Depth 99
	$response = Invoke-RestMethod -Uri $Uris.PatchScanTemplates -Method Post -Body $body -ContentType "application/json" -Credential $runAsCredential -Verbose
	return $response
}
 
function Add-PatchDeployTemplate
{
	Param
	(
		[String]$templateName,
		[PSCredential]$runAsCredential
	)
 
	#never reboot
	if ($reboot)
	{
		# You want to reboot the machine immediately
		$body =@{
			name = $templateName;
			PostDeploymentReboot = @{
				options = @{
					powerState = 'Restart';
					countdownMinutes = 2;
					extendMinutes = 1;
					forceActionAfterMinutes = 1;
					loggedOnUserAction = 'ForceActionAfterMinutes';
					systemDialogSeconds = 10;
					userOptions = 'AllowExtension';
				}
			when = 'ImmediateIfRequired'
			}
		} | ConvertTo-Json -Depth 99;
	}
	else
	{
		$body =@{
			name = $templateName;
			PostDeploymentReboot = @{
			when = 'NoReboot'
			}
		} | ConvertTo-Json -Depth 99;
	}
 
	$response = Invoke-RestMethod -Uri $Uris.PatchDeployTemplates -Method Post -Body $body -ContentType "application/json" -Credential $runAsCredential -Verbose
	return $response
}
 
function Invoke-PatchAndDeploy
{
	Param
	(
		[String]$ScanTemplateName,
		[String]$MachineGroupName,
		[String]$DeployTemplateName,
		[String]$ScanName,
		[String]$runAsCredentialId,
		[PSCredential]$runAsCredential
	)
 
	# Find scan template
	$allScanTemplates = Get-PaginatedResults $Uris.PatchScanTemplates $runAsCredential
	$foundScanTemplate = $allScanTemplates | Where-Object { $_.Name -eq $ScanTemplateName }
	if ($null -eq $foundScanTemplate)
	{
		Write-Error ("could not find patch scan template with name " + $ScanTemplateName)
	}
 
	# find machine group
	$allMachineGroups = Get-PaginatedResults $Uris.MachineGroups $runAsCredential
	$foundMachineGroup = $allMachineGroups | Where-Object { $_.Name -eq $MachineGroupName }
	if ($null -eq $foundMachineGroup)
	{
		Write-Error ("could not find machine group with name " + $MachineGroupName)
	}
 
	# Find deploy template
	$allDeployTemplates = Get-PaginatedResults $Uris.PatchDeployTemplates $runAsCredential
	$foundDeployTemplate = $allDeployTemplates | Where-Object { $_.Name -eq $DeployTemplateName }
	if ($null -eq $foundDeployTemplate)
	{
		Write-Error ("could not find patch deploy template with name " + $DeployTemplateName)
	}
 
	# perform the scan
	$body = @{ MachineGroupIds = @( $foundMachineGroup.id ); Name = $ScanName; TemplateId = $foundScanTemplate.id; RunAsCredentialId = $runAsCredentialId } | ConvertTo-Json -Depth 99
	Write-Host "Starting scan"
	$scanOperation = Invoke-WebRequest -Uri $Uris.PatchScans -Method Post -Body $body -Credential $runAsCredential -Verbose -ContentType 'application/json'
 
	# wait for scan to complete
	$completedScan = Wait-Operation $scanOperation.headers['Operation-Location'] 5 $runAsCredential
 
	# get the scan id for future use
	$scan = Invoke-RestMethod -Uri $completedScan.resourceLocation -Credential $runAsCredential -Verbose -Method GET
	Write-Host ( "Scan complete " + $scan.id)
 
	# get the scan id for future use
	$machines = Invoke-RestMethod -Uri $scan.links.machines.href -Credential $runAsCredential -Verbose -Method GET
 
	foreach ($machineScanned in $machines)
	{
		foreach ($value in $machineScanned.value)
		{
			if (($value.installedPatchCount -gt 0) -or ($value.missingPatchCount -gt 0))
			{
				$patches = Invoke-RestMethod -Uri $value.links.patches.href -Credential $runAsCredential -Verbose -Method GET
				foreach ($patch in $patches.value)
				{
					if ($deployPatches -eq $false -or $patch.scanState -ne "MissingPatch")
					{
						Write-Host ( $patch.bulletinId + " / " + $patch.kb + " (" + $patch.scanState + ") - NOT being deployed." )
					}
					else
					{
						Write-Host ( $patch.bulletinId + " / " + $patch.kb + " (" + $patch.scanState + ") - DEPLOYING." )
					}
				}
			}
			else
			{
				Write-Host ( "No patches were found")
			}
		}
	}
	# perform the deployment
	if ($deployPatches)
	{
		Write-Host "Starting deployment"
		$body = @{ ScanId=$scan.id; TemplateId = $foundDeployTemplate.id; RunAsCredentialId = $runAsCredentialId } | ConvertTo-Json -Depth 99
		$deploy = Invoke-WebRequest -Uri $Uris.PatchDeployments -Method Post -Body $body -Credential $runAsCredential -Verbose -ContentType 'application/json'
 
		# wait until deployment has a deployment resource location
		$operationUri = $deploy.Headers['Operation-Location']
		$operation = Invoke-RestMethod -Uri $operationUri -Credential $runAsCredential -Verbose -Method GET
 
		while((($null -eq $operation.resourceLocation) -or ($operation.operation -eq "PatchDownload")) -and -not ($operation.status -eq "Succeeded"))
		{
			if (($operation.operation -eq "PatchDownload") -and ($null -ne $operation.percentComplete))
			{
				Write-Host ("Downloading patches..." + $operation.percentComplete + "%")
			}
			Start-Sleep -Seconds 1
			$operation = Invoke-RestMethod -Uri $operationUri -Credential $runAsCredential -Verbose -Method GET
		}
 
		# It's possible we didn't have anything to patch in which case we're already succeeded.
		# If so, don't both getting machine statuses as it will never return anything good.
		if (-not $operation.status -eq "Succeeded")
		{
			# start getting deployment detailed status updates
			$statusUri = $deploy.Headers['Location'] + '/machines'
			$machineStatuses = Invoke-RestMethod $statusUri -Credential $runAsCredential -Verbose -Method GET
 
			# now start getting and displaying the statuses
			while(($machineStatuses.value[0].overallState -ne "Complete") -and ($machineStatuses.value[0].overallState -ne "Failed"))
			{
				Write-Host ("Overall Status = " + $machineStatuses.value[0].overallState)
				Write-Host ("Status Description = " + $machineStatuses.value[0].statusDescription)
 
				$updateDelaySeconds = 30
 
				# only check for new updates every $updateDelaySeconds
				Start-Sleep  -Seconds $updateDelaySeconds
				$machineStatuses = Invoke-RestMethod $statusUri -Credential $runAsCredential -Verbose -Method GET
			}
		}
		Write-Host "Deployment scheduled"
	}
	else
	{
		Write-Host "You specified NOT to Deploy the patches."
	}
}
 
function Invoke-ScanAndDeploy
{
	Param
	(
		[parameter(Mandatory = $true)]
		[String]$machineToScan = $(throw "Must supply a machine to scan."),
		[parameter(Mandatory = $false)]
		[String[]]$cveToScanFor,
		[parameter(Mandatory = $true)]
		[PSCredential]$runAsCredential = $(throw "Must supply run as credentials."),
		[parameter(Mandatory = $true)]
		[PSCredential]$loginCredential = $(throw "Must supply your logged on credentials.")
	)
 
	$toDelete = [System.Collections.ArrayList]@()
	try
	{
		$uid = [Guid]::NewGuid()
		$loginCredentialName = "Sample Admin Credential -" + $uid
		$loginCredentialRef = Add-Credential $loginCredentialName $loginCredential $runAsCredential
		$toDelete.Add($loginCredentialRef.links.self.href) > $null
		$runAsCredentialName = "Sample REST Invoke Credential -" + $uid
		$runAsCredentialRef = Add-Credential $runAsCredentialName $runAsCredential $runAsCredential
		$toDelete.Add($runAsCredentialRef.links.self.href) > $null
		$machineGrouplName = "Sample Machine Group -" + $uid
		$response = Add-MachineGroup $machineGrouplName $machineToScan $loginCredentialRef.id $runAsCredential
		$toDelete.Add($response.links.self.href) > $null
		$patchGroupName = "Sample Patch Group -" + $uid
		$patchGroupRef = Add-PatchGroup $patchGroupName $runAsCredential
		Add-NullPatchToPatchGroup $patchGroupRef.id $runAsCredential
		$cveToScanFor | ForEach-Object { Add-CveToPatchGroup $patchGroupRef.id $_ $runAsCredential }
		$toDelete.Add($patchGroupRef.links.self.href) > $null
		$scanTemplateName = "Sample Scan Template-" + $uid
		$response = Add-PatchScanTemplate $scanTemplateName $patchGroupRef.id $runAsCredential
		$toDelete.Add($response.links.self.href) > $null
		$deployTemplateName = "Sample Deploy Template -" + $uid
		$response = Add-PatchDeployTemplate $deployTemplateName $runAsCredential
		$toDelete.Add($response.links.self.href) > $null
		Invoke-PatchAndDeploy -ScanTemplateName $scanTemplateName -MachineGroupName $machineGrouplName -DeployTemplateName $deployTemplateName -ScanName $uid -RunAsCredential $runAsCredential -RunAsCredentialId $runAsCredentialRef.id
	}
	finally
	{
		if ($deleteSampleData)
		{
			# cleanup collateral
			$toDelete.Reverse();
			$toDelete | ForEach-Object { Remove-RestResourceSafe $_ $runAsCredential }
		}
		else
		{
			Write-Host "You did NOT want to delete the sample data."
		}
	}
}
#####################################
#	Start Script
#####################################
try
{
	# Who do you want to run the REST API invoke calls
	$RESTInvokeCredential = Get-Credential $loggedOnUserName
 
	# The machine to scan's administrator credentials
	$adminCredential = Get-Credential $loggedOnUserName
 
	Invoke-ScanAndDeploy $machineToScan $cveList $RESTInvokeCredential $adminCredential
}
catch [Exception]
{
	$private:e = $_.Exception
	do
	{
		Write-Host "Error: " $private:e
		$private:e = $private:e.InnerException
	}
	while ($private:e -ne $null)
}